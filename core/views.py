import django_filters
import json
import logging
import random
import string
from datetime import timedelta

from django.conf import settings
from django.shortcuts import render
from rest_framework import generics
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view
from rest_framework.decorators import permission_classes
from .models import *
from .serializers import *
from .services import *
from .constants import devise_pour_pays
from .telephone import candidats_suffixe_telephone
from rest_framework.views import APIView
from rest_framework.exceptions import PermissionDenied
from rest_framework_simplejwt.views import TokenObtainPairView
from django.utils import timezone
from django.db import transaction
from django.db.models import Q

logger = logging.getLogger(__name__)


class LoginView(TokenObtainPairView):

    serializer_class = TelephoneTokenObtainPairSerializer


@api_view(['GET'])
def api_root(request):
    return Response(
        {
            "message": "Bienvenue sur l'API AfriFlotte",
            "endpoints": {
                "register": "/api/register/",
                "login": "/api/login/",
                "token_refresh": "/api/token/refresh/",
                "camions": "/api/camions/",
                "camions_images": "/api/camions/images/",
                "chauffeurs": "/api/chauffeurs/",
                "affectations": "/api/affectations/",
                "demandes": "/api/demandes/",
                "missions": "/api/missions/",
                "missions_create": "/api/missions/create/",
                "dashboard": "/api/dashboard/",
                "recherche_camions": "/api/recherche-camions/",
                "flotte_positions": "/api/transporteur/flotte-positions/",
                "profil": "/api/profil/",
                "propositions": "/api/propositions/",
                "tracking": "/api/tracking/",
                "chauffeur_login": "/api/chauffeur/login/",
                "transporteur_dashboard": "/api/transporteur/dashboard/",
                "client_dashboard": "/api/client/dashboard/",
                "admin_dashboard": "/api/admin/dashboard/",
                "notifications": "/api/notifications/",
            },
        }
    )


class UserCreateView(generics.CreateAPIView):

    queryset = User.objects.all()
    serializer_class = UserSerializer

class ImageCamionCreateView(generics.CreateAPIView):

    serializer_class = ImageCamionCreateSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        camion = serializer.validated_data["camion"]

        if camion.proprietaire != self.request.user:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Vous ne pouvez ajouter une image qu'à votre propre camion.")

        from django.core.exceptions import ValidationError
        from rest_framework.exceptions import ValidationError as DRFValidationError

        # La toute première image d'un camion devient automatiquement la
        # principale, même si le client n'a rien précisé.
        premiere_image = not camion.images.exists()
        principale = premiere_image or serializer.validated_data.get("principale", False)

        try:
            instance = serializer.save(principale=principale)

            if instance.principale:
                camion.images.exclude(pk=instance.pk).update(principale=False)

        except ValidationError as e:
            raise DRFValidationError({"detail": e.messages})
        except Exception as e:
            raise DRFValidationError({"detail": str(e)})


class ImageCamionDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Gestion d'une photo existante : la définir comme principale (PATCH
    `{"principale": true}`) ou la supprimer. Remplacer l'image elle-même
    n'est pas supporté ici — il faut la supprimer puis en ajouter une
    nouvelle via `ImageCamionCreateView`."""

    serializer_class = ImageCamionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return ImageCamion.objects.filter(
            camion__proprietaire=self.request.user
        )

    def perform_update(self, serializer):
        from django.core.exceptions import ValidationError
        from rest_framework.exceptions import ValidationError as DRFValidationError

        # Même garde qu'ImageCamionCreateView.perform_create : sans lui, une
        # ValidationError levée par ImageCamion.save() remontait telle
        # quelle en 500 au lieu d'un 400 lisible.
        try:
            instance = serializer.save()
        except ValidationError as e:
            raise DRFValidationError({"detail": e.messages})

        if instance.principale:
            instance.camion.images.exclude(
                pk=instance.pk
            ).update(principale=False)


class DemandeTransportListCreateView(
    generics.ListCreateAPIView
):

    serializer_class = DemandeTransportSerializer

    permission_classes = [IsAuthenticated]


    def get_queryset(self):

        user = self.request.user

        queryset = DemandeTransport.objects.select_related(
            "client"
        )

        # Client : uniquement ses propres demandes.
        if user.type_compte == "ENTREPRISE":

            return queryset.filter(
                client=user
            ).order_by("-date_creation")


        # Transporteur : les demandes encore ouvertes du marché.
        if user.type_compte == "TRANSPORTEUR":

            return queryset.filter(
                statut="OUVERTE"
            ).order_by("-date_creation")


        return queryset.order_by("-date_creation")


    def perform_create(self, serializer):

        demande = serializer.save(
            client=self.request.user
        )

        proposer_camions_pour_demande(demande)


class DemandeDetailView(generics.RetrieveUpdateAPIView):
    """Consultation/modification d'une demande par son client.

    Pas de DELETE : une demande déjà vue par des transporteurs ne doit pas
    disparaître silencieusement (même raison que Camion/Chauffeur). La
    modification elle-même est bloquée une fois la demande plus OUVERTE
    (cf. DemandeTransportSerializer.validate).
    """

    serializer_class = DemandeTransportSerializer

    permission_classes = [
        IsAuthenticated
    ]

    def get_queryset(self):

        return DemandeTransport.objects.filter(
            client=self.request.user
        )


class MissionCreateView(generics.CreateAPIView):

    queryset = Mission.objects.all()

    serializer_class = MissionSerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def accepter_mission(request, id):
    """Démarre une mission planifiée : PLANIFIEE -> EN_COURS, bloque le(s)
    camion(s)/chauffeur(s) qui y participent (symétrique de `terminer_mission`).

    Avant ce correctif, cette vue faisait `mission.camion.disponible = False`
    alors que `Mission` n'a pas de champ `camion` (les camions d'une mission
    passent par `MissionCamion`) : tout appel levait une AttributeError. Elle
    assignait aussi `mission.statut = "ACCEPTEE"`, une valeur absente de
    `Mission.Statut` (PLANIFIEE/EN_COURS/TERMINEE/ANNULEE).
    """

    try:
        mission = Mission.objects.select_related(
            "transporteur"
        ).get(id=id)

    except Mission.DoesNotExist:
        return Response(
            {"message": "Mission introuvable"},
            status=404
        )

    if mission.transporteur_id != request.user.id:
        return Response(
            {"message": "Vous ne pouvez pas démarrer cette mission."},
            status=403
        )

    try:
        demarrer_mission_service(mission)
    except ValueError as e:
        return Response({"message": str(e)}, status=400)

    return Response(
        {
            "message": "Mission démarrée",
            "mission": mission.id
        }
    )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def terminer_mission(request, id):
    """Clôture une mission : le/les camion(s) et chauffeur(s) redeviennent
    disponibles, sans toucher à l'affectation chauffeur ↔ camion — le
    chauffeur reste associé à son camion, c'est cette affectation qui permet
    de continuer à localiser le camion via son téléphone une fois la mission
    terminée."""

    try:
        mission = Mission.objects.select_related(
            "transporteur"
        ).get(id=id)

    except Mission.DoesNotExist:
        return Response(
            {"message": "Mission introuvable"},
            status=404
        )

    if mission.transporteur_id != request.user.id:
        return Response(
            {"message": "Vous ne pouvez pas terminer cette mission."},
            status=403
        )

    terminer_mission_service(mission)

    return Response(
        {
            "message": "Mission terminée",
            "mission": mission.id
        }
    )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def refuser_mission(request, id):
    """Annule une mission (planifiée ou en cours) -> ANNULEE, et libère le(s)
    camion(s)/chauffeur(s) si la mission avait déjà démarré (idempotent :
    les remettre disponibles quand ils l'étaient déjà ne fait rien).

    Avant ce correctif, assignait `mission.statut = "REFUSEE"`, une valeur
    absente de `Mission.Statut` — Django ne rejette pas l'écriture (les
    `choices` ne sont vérifiés qu'à la validation, pas en base), donc ça
    s'enregistrait silencieusement sans jamais rien libérer.
    """

    try:
        mission = Mission.objects.select_related(
            "transporteur"
        ).get(id=id)

    except Mission.DoesNotExist:
        return Response(
            {"message": "Mission introuvable"},
            status=404
        )

    if mission.transporteur_id != request.user.id:
        return Response(
            {"message": "Vous ne pouvez pas annuler cette mission."},
            status=403
        )

    if mission.statut in (Mission.Statut.TERMINEE, Mission.Statut.ANNULEE):
        return Response(
            {"message": "Cette mission ne peut plus être annulée."},
            status=400
        )

    with transaction.atomic():

        mission.statut = Mission.Statut.ANNULEE
        mission.save()

        # Rouvre la demande sur le marché : le besoin de transport de
        # l'entreprise n'a pas disparu parce qu'un transporteur s'est
        # désisté — symétrique de la libération du camion/chauffeur
        # ci-dessous, et ce qui permet à un autre transporteur de la voir
        # à nouveau dans "Demandes disponibles" (filtré sur statut=OUVERTE).
        mission.demande.statut = "OUVERTE"
        mission.demande.save(update_fields=["statut"])

        for mission_camion in mission.camions.select_related("camion", "chauffeur"):

            mission_camion.camion.disponible = True
            mission_camion.camion.save(update_fields=["disponible"])

            if mission_camion.chauffeur_id:
                mission_camion.chauffeur.disponible = True
                mission_camion.chauffeur.save(update_fields=["disponible"])

        # Additif : rembourse le paiement s'il avait déjà été encaissé/
        # sécurisé. No-op silencieux si la mission n'a pas de paiement.
        rembourser_paiement_service(mission, request.user, "Mission annulée par le transporteur.")

    notifier(
        mission.client,
        Notification.Type.MISSION_ANNULEE,
        f"Votre mission {mission.demande.ville_depart} → {mission.demande.ville_arrivee} a été annulée."
    )

    return Response(
        {
            "message": "Mission annulée"
        }
    )


# ==========================
# PAIEMENTS
# ==========================

def _paiement_ou_404(id):
    try:
        return Paiement.objects.select_related(
            'mission__client', 'mission__transporteur', 'mission__demande'
        ).get(id=id)
    except Paiement.DoesNotExist:
        return None


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def initier_paiement(request, mission_id):
    """Le client de la mission choisit son mode de paiement et crée le
    Paiement associé. En mode CARTE, initie aussi la transaction côté
    passerelle (obtient une référence) — le client saisit ensuite sa carte
    dans le formulaire intégré côté Flutter, confirmé via
    `confirmer_paiement_carte` ci-dessous."""
    try:
        mission = Mission.objects.select_related('demande', 'client').get(id=mission_id)
    except Mission.DoesNotExist:
        return Response({"message": "Mission introuvable"}, status=404)

    mode = request.data.get('mode')

    try:
        paiement = creer_paiement_service(mission, mode, request.user)
    except PermissionError as e:
        return Response({"message": str(e)}, status=403)
    except ValueError as e:
        return Response({"message": str(e)}, status=400)

    reponse = PaiementSerializer(paiement).data

    if paiement.mode == Paiement.Mode.CARTE:
        transaction_psp = initier_paiement_carte_service(paiement)
        paiement.refresh_from_db()
        reponse = PaiementSerializer(paiement).data
        if transaction_psp.get('checkout_url'):
            reponse['checkout_url'] = transaction_psp['checkout_url']

    return Response(reponse, status=201)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def confirmer_paiement_carte(request, id):
    """Confirmation depuis le formulaire carte intégré côté Flutter (plus de
    page externe/webhook pour ce flux) : le client vient de saisir sa carte,
    on interroge la passerelle (`verifier_transaction`, toujours "REUSSI" en
    mode simulateur) puis on route vers `confirmer_paiement_carte_service`.

    Seules marque/4-derniers-chiffres/expiration sont attendus dans le corps
    — jamais le numéro complet ni le CVV, qui ne doivent jamais atteindre
    Django (cf. core/gateway_paiement.py)."""
    try:
        paiement = Paiement.objects.select_related('mission').get(id=id)
    except Paiement.DoesNotExist:
        return Response({"message": "Paiement introuvable"}, status=404)

    if paiement.mission.client_id != request.user.id:
        return Response({"message": "Accès non autorisé."}, status=403)

    if paiement.mode != Paiement.Mode.CARTE:
        return Response({"message": "Ce paiement n'est pas en mode carte."}, status=400)

    if paiement.statut != Paiement.Statut.EN_ATTENTE:
        return Response(PaiementSerializer(paiement).data, status=200)

    statut_psp = get_gateway().verifier_transaction(paiement.reference_externe)

    if statut_psp == "EN_ATTENTE":
        return Response(PaiementSerializer(paiement).data, status=202)

    carte_info = {
        "marque": str(request.data.get('carte_marque', ''))[:20],
        "dernier4": str(request.data.get('carte_dernier4', ''))[:4],
        "expiration": str(request.data.get('carte_expiration', ''))[:5],
    }

    paiement = confirmer_paiement_carte_service(paiement.reference_externe, statut_psp, carte_info)

    return Response(PaiementSerializer(paiement).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def detail_paiement_mission(request, mission_id):
    """Détail du paiement d'une mission — client, transporteur ou admin
    concernés uniquement."""
    try:
        mission = Mission.objects.select_related('demande', 'client', 'transporteur').get(id=mission_id)
    except Mission.DoesNotExist:
        return Response({"message": "Mission introuvable"}, status=404)

    user = request.user
    if user.id not in (mission.client_id, mission.transporteur_id) and user.type_compte != 'ADMIN':
        return Response({"message": "Accès non autorisé."}, status=403)

    try:
        paiement = mission.paiement
    except Paiement.DoesNotExist:
        return Response({"message": "Aucun paiement pour cette mission."}, status=404)

    return Response(PaiementSerializer(paiement).data)


def _extraire_reference_webhook(donnees):
    """Le simulateur envoie un payload plat `{"reference": ..., "statut":
    ...}`. PayDunya envoie une notification IPN dont le format exact n'est
    pas garanti à 100% par sa documentation (form-encodé, clé `data`
    imbriquée — chaîne JSON ou clés séparées selon les cas observés) : on
    essaie les deux formes plutôt que de supposer une seule. Renvoie
    `(reference, sous_donnees)` où `sous_donnees` est le dict à passer à
    `verifier_authenticite_webhook` (contient le `hash` PayDunya s'il y en a
    un)."""
    reference = donnees.get('reference')
    if reference:
        return reference, donnees

    brut = donnees.get('data')
    if isinstance(brut, str):
        try:
            brut = json.loads(brut)
        except (TypeError, ValueError):
            brut = {}
    if isinstance(brut, dict):
        return brut.get('token') or brut.get('reference'), brut

    return None, donnees


@api_view(['POST'])
def paiement_webhook(request):
    """Callback PSP asynchrone confirmant une transaction carte. Route
    ouverte (le PSP n'a pas de JWT AfriFlotte) — l'authenticité est vérifiée
    par `get_gateway().verifier_authenticite_webhook()`, propre à chaque
    prestataire (cf. core/gateway_paiement.py).

    Le statut indiqué dans le payload n'est JAMAIS appliqué directement : on
    re-vérifie systématiquement auprès du PSP via `verifier_transaction`
    (recommandation PayDunya elle-même) avant de faire progresser le
    paiement — le webhook ne sert qu'à déclencher cette vérification, pas à
    être une source de vérité en lui-même."""
    logger.info("Webhook paiement reçu : %s", dict(request.data))

    gateway = get_gateway()
    reference, sous_donnees = _extraire_reference_webhook(request.data)

    if not gateway.verifier_authenticite_webhook(sous_donnees):
        return Response({"message": "Signature invalide."}, status=403)

    if not reference:
        return Response({"message": "Référence de transaction manquante."}, status=400)

    statut_reel = gateway.verifier_transaction(reference)

    try:
        paiement = confirmer_paiement_carte_service(reference, statut_reel)
    except ValueError as e:
        return Response({"message": str(e)}, status=404)

    return Response({"message": "OK", "paiement": paiement.id})


def paiement_retour(request):
    """Page affichée si PayDunya redirige le navigateur avant que la WebView
    Flutter n'ait pu intercepter la navigation (filet de sécurité — en
    fonctionnement normal, l'app ferme la WebView avant que cette page ne
    s'affiche vraiment). Le vrai statut du paiement est confirmé côté serveur
    par le webhook (`paiement_webhook`), pas par cette page."""
    from django.http import HttpResponse

    return HttpResponse("<h1>Paiement reçu</h1><p>Vous pouvez revenir à l'application AfriFlotte.</p>")


def paiement_annule(request):
    """Page affichée si le client annule le paiement sur la page PayDunya
    avant que la WebView Flutter n'intercepte la navigation."""
    from django.http import HttpResponse

    return HttpResponse("<h1>Paiement annulé</h1><p>Vous pouvez revenir à l'application AfriFlotte.</p>")


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def encaisser_paiement_manuel(request, id):
    """Un agent AfriFlotte déclare avoir encaissé l'argent du client en
    espèces, avec une preuve (photo du reçu/signature)."""
    paiement = _paiement_ou_404(id)
    if paiement is None:
        return Response({"message": "Paiement introuvable"}, status=404)

    try:
        paiement = encaisser_paiement_manuel_service(
            paiement,
            agent=request.user,
            reference=request.data.get('reference', ''),
            preuve_fichier=request.FILES.get('preuve'),
            commentaire=request.data.get('commentaire', ''),
        )
    except PermissionError as e:
        return Response({"message": str(e)}, status=403)
    except ValueError as e:
        return Response({"message": str(e)}, status=400)

    return Response(PaiementSerializer(paiement).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def valider_paiement_manuel(request, id):
    paiement = _paiement_ou_404(id)
    if paiement is None:
        return Response({"message": "Paiement introuvable"}, status=404)

    try:
        paiement = valider_paiement_manuel_service(paiement, request.user)
    except PermissionError as e:
        return Response({"message": str(e)}, status=403)
    except ValueError as e:
        return Response({"message": str(e)}, status=400)

    return Response(PaiementSerializer(paiement).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verser_paiement(request, id):
    paiement = _paiement_ou_404(id)
    if paiement is None:
        return Response({"message": "Paiement introuvable"}, status=404)

    try:
        paiement = marquer_verse_service(
            paiement,
            admin=request.user,
            reference=request.data.get('reference', ''),
            preuve_fichier=request.FILES.get('preuve'),
            commentaire=request.data.get('commentaire', ''),
        )
    except PermissionError as e:
        return Response({"message": str(e)}, status=403)
    except ValueError as e:
        return Response({"message": str(e)}, status=400)

    return Response(PaiementSerializer(paiement).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def rembourser_paiement_endpoint(request, id):
    paiement = _paiement_ou_404(id)
    if paiement is None:
        return Response({"message": "Paiement introuvable"}, status=404)

    if request.user.type_compte != 'ADMIN':
        return Response({"message": "Accès réservé aux administrateurs."}, status=403)

    motif = request.data.get('motif', '')
    resultat = rembourser_paiement_service(paiement.mission, request.user, motif)

    if resultat is None or resultat.statut != Paiement.Statut.REMBOURSE:
        return Response({"message": "Ce paiement ne peut pas être remboursé dans son état actuel."}, status=400)

    return Response(PaiementSerializer(resultat).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def ouvrir_litige(request, id):
    paiement = _paiement_ou_404(id)
    if paiement is None:
        return Response({"message": "Paiement introuvable"}, status=404)

    motif = request.data.get('motif', '')
    if not motif:
        return Response({"message": "Le motif du litige est obligatoire."}, status=400)

    try:
        litige = ouvrir_litige_service(paiement, request.user, motif)
    except PermissionError as e:
        return Response({"message": str(e)}, status=403)
    except ValueError as e:
        return Response({"message": str(e)}, status=400)

    return Response(LitigeSerializer(litige).data, status=201)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def resoudre_litige(request, id):
    try:
        litige = Litige.objects.select_related(
            'paiement__mission__client', 'paiement__mission__transporteur', 'paiement__mission__demande'
        ).get(id=id)
    except Litige.DoesNotExist:
        return Response({"message": "Litige introuvable"}, status=404)

    try:
        litige = resoudre_litige_service(
            litige,
            admin=request.user,
            resolution=request.data.get('resolution'),
            commentaire=request.data.get('commentaire', ''),
        )
    except PermissionError as e:
        return Response({"message": str(e)}, status=403)
    except ValueError as e:
        return Response({"message": str(e)}, status=400)

    return Response(LitigeSerializer(litige).data)


class AgentPaiementsView(generics.ListAPIView):
    """Paiements MANUEL en attente d'encaissement, visibles par tout agent
    AfriFlotte — pas de notion de propriété ici (contrairement à
    MesPaiementsView) : un agent est du personnel AfriFlotte, pas une partie
    à la mission, donc n'importe quel agent peut aller encaisser n'importe
    quel paiement manuel en attente."""

    serializer_class = PaiementSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if self.request.user.type_compte != 'AGENT':
            return Paiement.objects.none()

        return Paiement.objects.select_related(
            'mission__demande', 'mission__client', 'mission__transporteur'
        ).filter(mode=Paiement.Mode.MANUEL, statut=Paiement.Statut.EN_ATTENTE)

    def list(self, request, *args, **kwargs):
        if request.user.type_compte != 'AGENT':
            return Response({"message": "Accès réservé aux agents AfriFlotte."}, status=403)
        return super().list(request, *args, **kwargs)


class MesPaiementsView(generics.ListAPIView):
    """Historique des paiements du client ou du transporteur connecté."""

    serializer_class = PaiementSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        queryset = Paiement.objects.select_related(
            'mission__demande', 'mission__client', 'mission__transporteur'
        )

        if user.type_compte == 'TRANSPORTEUR':
            return queryset.filter(mission__transporteur=user)

        return queryset.filter(mission__client=user)


class AdminPaiementsView(generics.ListAPIView):
    """File d'attente admin : paiements manuels à valider et paiements
    libérés à verser, par défaut — filtrable par `?statut=`."""

    serializer_class = PaiementSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if self.request.user.type_compte != 'ADMIN':
            return Paiement.objects.none()

        queryset = Paiement.objects.select_related(
            'mission__demande', 'mission__client', 'mission__transporteur'
        )

        statut = self.request.query_params.get('statut')
        if statut:
            return queryset.filter(statut=statut)

        return queryset.filter(statut__in=[Paiement.Statut.ENCAISSE, Paiement.Statut.LIBERE])

    def list(self, request, *args, **kwargs):
        if request.user.type_compte != 'ADMIN':
            return Response({"message": "Accès réservé aux administrateurs."}, status=403)
        return super().list(request, *args, **kwargs)


class AdminLitigesView(generics.ListAPIView):
    """File d'attente admin des litiges — `?statut=` par défaut sur les
    litiges encore ouverts."""

    serializer_class = LitigeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if self.request.user.type_compte != 'ADMIN':
            return Litige.objects.none()

        queryset = Litige.objects.select_related(
            'paiement__mission__demande', 'paiement__mission__client', 'paiement__mission__transporteur'
        )

        statut = self.request.query_params.get('statut')
        if statut:
            return queryset.filter(statut=statut)

        return queryset.filter(statut__in=[Litige.Statut.OUVERT, Litige.Statut.EN_EXAMEN])

    def list(self, request, *args, **kwargs):
        if request.user.type_compte != 'ADMIN':
            return Response({"message": "Accès réservé aux administrateurs."}, status=403)
        return super().list(request, *args, **kwargs)


# ==========================
# ADMIN : vues plateforme (non scopées à request.user)
# ==========================
#
# Les écrans de liste "normaux" (ListeCamions, ListeChauffeurs, MissionListView...)
# sont tous filtrés sur le propriétaire connecté — inutilisables tels quels
# pour un admin qui doit voir toute la plateforme. Ces vues renvoient tout,
# sans filtre côté serveur : comme MissionListView déjà consommée par
# MissionsClientScreen, le filtrage (statut, disponibilité...) se fait côté
# Flutter via des chips, pour éviter un aller-retour réseau à chaque
# changement de filtre.

class AdminUtilisateursView(generics.ListAPIView):
    """Comptes TRANSPORTEUR ou ENTREPRISE de toute la plateforme — `type_compte`
    est obligatoire en query param pour ne jamais lister par erreur les
    comptes ADMIN/AGENT au même endroit."""

    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        type_compte = self.request.query_params.get('type_compte')
        if type_compte not in ('TRANSPORTEUR', 'ENTREPRISE'):
            return User.objects.none()
        return User.objects.filter(type_compte=type_compte).order_by('-date_creation')

    def list(self, request, *args, **kwargs):
        if request.user.type_compte != 'ADMIN':
            return Response({"message": "Accès réservé aux administrateurs."}, status=403)
        if request.query_params.get('type_compte') not in ('TRANSPORTEUR', 'ENTREPRISE'):
            return Response({"message": "Paramètre type_compte requis (TRANSPORTEUR ou ENTREPRISE)."}, status=400)
        return super().list(request, *args, **kwargs)


class AdminChauffeursView(generics.ListAPIView):
    """Tous les chauffeurs de tous les transporteurs."""

    serializer_class = ChauffeurSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Chauffeur.objects.select_related('transporteur').order_by('-created_at')

    def list(self, request, *args, **kwargs):
        if request.user.type_compte != 'ADMIN':
            return Response({"message": "Accès réservé aux administrateurs."}, status=403)
        return super().list(request, *args, **kwargs)


class AdminCamionsView(generics.ListAPIView):
    """Tous les camions de tous les transporteurs."""

    serializer_class = CamionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Camion.objects.select_related('proprietaire').prefetch_related('images').order_by('-date_creation')

    def list(self, request, *args, **kwargs):
        if request.user.type_compte != 'ADMIN':
            return Response({"message": "Accès réservé aux administrateurs."}, status=403)
        return super().list(request, *args, **kwargs)


class AdminMissionsView(generics.ListAPIView):
    """Toutes les missions de la plateforme, tous clients/transporteurs confondus."""

    serializer_class = MissionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Mission.objects.select_related(
            'demande', 'client', 'transporteur'
        ).prefetch_related('camions')

    def list(self, request, *args, **kwargs):
        if request.user.type_compte != 'ADMIN':
            return Response({"message": "Accès réservé aux administrateurs."}, status=403)
        return super().list(request, *args, **kwargs)


class AdminDemandesView(generics.ListAPIView):
    """Toutes les demandes de transport de la plateforme, tous clients confondus."""

    serializer_class = DemandeTransportSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return DemandeTransport.objects.select_related('client').order_by('-date_creation')

    def list(self, request, *args, **kwargs):
        if request.user.type_compte != 'ADMIN':
            return Response({"message": "Accès réservé aux administrateurs."}, status=403)
        return super().list(request, *args, **kwargs)


@api_view(['GET'])
def dashboard(request):

    user = request.user


    if user.type_compte == "TRANSPORTEUR":

        data = {

            "type": "TRANSPORTEUR",

            "camions": Camion.objects.filter(
                proprietaire=user
            ).count(),

            "camions_disponibles": Camion.objects.filter(
                proprietaire=user,
                disponible=True
            ).count(),

            "missions": Mission.objects.filter(
                transporteur=user
            ).count(),

            "missions_en_attente": Mission.objects.filter(
                transporteur=user,
                statut=Mission.Statut.PLANIFIEE
            ).count(),

        }


    elif user.type_compte == "ENTREPRISE":

        data = {

            "type": "ENTREPRISE",

            "demandes": DemandeTransport.objects.filter(
                client=user
            ).count(),

            "missions": Mission.objects.filter(
                demande__client=user
            ).count(),

        }


    else:

        data = {

            "type": "ADMIN",

            "utilisateurs": User.objects.count()

        }


    return Response(data)






class RechercheCamionFilter(django_filters.FilterSet):

    capacite_min = django_filters.NumberFilter(
        field_name='capacite',
        lookup_expr='gte'
    )

    class Meta:
        model = Camion
        fields = [
            'type_camion',
            'format_camion',
            'ville',
            'pays',
            'disponible',
            'capacite_min',
        ]


class RechercheCamionView(
    generics.ListAPIView
):
    """Recherche de camions disponibles, triés par pertinence.

    `?latitude=..&longitude=..` (optionnel) donne le point de référence de la
    recherche (ex. la ville de départ d'une demande) : les camions sont alors
    triés par distance à ce point, avec un bonus/malus selon la fraîcheur de
    la position résolue (`resoudre_position_camion`, cf. core/services.py) —
    un camion plus loin mais avec une position à jour peut passer devant un
    camion plus proche mais dont la position date de plusieurs heures. Un
    camion sans position résolue n'est pas exclu, juste renvoyé en dernier.
    Sans point de référence, le tri se fait uniquement sur la fraîcheur.
    """

    serializer_class = CamionRechercheSerializer

    queryset = Camion.objects.filter(
        disponible=True
    ).select_related(
        'proprietaire'
    ).prefetch_related(
        'images',
        'affectations__chauffeur',
    )

    filter_backends = [
        DjangoFilterBackend
    ]

    filterset_class = RechercheCamionFilter

    def list(self, request, *args, **kwargs):

        queryset = self.filter_queryset(self.get_queryset())

        reference = self._point_reference(request)
        camions = list(queryset)

        for camion in camions:

            position = resoudre_position_camion(camion)

            distance = (
                distance_km(
                    reference[0], reference[1],
                    position['latitude'], position['longitude']
                )
                if reference is not None and position is not None
                else None
            )

            camion._position_resolue = position
            camion._distance_km = distance
            camion._score = self._calculer_score(
                distance, position, reference_fournie=reference is not None
            )

        camions.sort(key=lambda camion: camion._score, reverse=True)

        serializer = self.get_serializer(camions, many=True)
        return Response(serializer.data)

    @staticmethod
    def _point_reference(request):

        latitude = request.query_params.get('latitude')
        longitude = request.query_params.get('longitude')

        if latitude is None or longitude is None:
            return None

        try:
            return float(latitude), float(longitude)
        except ValueError:
            return None

    @staticmethod
    def _calculer_score(distance, position, reference_fournie):

        fraicheur = position['fraicheur'] if position else 'INCONNUE'
        bonus = BONUS_FRAICHEUR.get(fraicheur, 0)

        if not reference_fournie:
            return bonus

        if distance is None:
            return -9999

        return bonus - distance





class FlottePositionsView(generics.ListAPIView):
    """Positions de la flotte du transporteur connecté : TOUS ses camions
    (disponibles ou en mission), chacun avec le chauffeur actuellement
    affecté et sa position résolue (`resoudre_position_camion`, même chaîne
    de priorité que RechercheCamionView : GPS propre du camion, sinon
    téléphone du chauffeur affecté, sinon valeur statique, sinon aucune).

    C'est l'écran "où sont mes camions/chauffeurs en ce moment" du
    transporteur — à ne pas confondre avec RechercheCamionView, qui sert la
    recherche marché côté client (camions disponibles uniquement, sans
    identité du chauffeur).
    """

    serializer_class = CamionFlotteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Camion.objects.filter(
            proprietaire=self.request.user
        ).select_related(
            'proprietaire'
        ).prefetch_related(
            'images',
            'affectations__chauffeur',
        )

    def list(self, request, *args, **kwargs):

        camions = list(self.get_queryset())

        for camion in camions:
            camion._position_resolue = resoudre_position_camion(camion)

        # Les positions les plus fraîches d'abord, les camions sans position
        # connue en dernier — même échelle de bonus que RechercheCamionView.
        camions.sort(
            key=lambda camion: BONUS_FRAICHEUR.get(
                camion._position_resolue['fraicheur']
                if camion._position_resolue else 'INCONNUE',
                0,
            ),
            reverse=True,
        )

        serializer = self.get_serializer(camions, many=True)
        return Response(serializer.data)


class CamionListCreateView(generics.ListCreateAPIView):

    serializer_class = CamionSerializer

    permission_classes = [
        IsAuthenticated
    ]



    def get_queryset(self):

        return Camion.objects.filter(
            proprietaire=self.request.user
        )



    def perform_create(self, serializer):

        serializer.save(
            proprietaire=self.request.user
        )


class CamionDetailView(generics.RetrieveUpdateAPIView):
    """Consultation/modification d'un camion du transporteur connecté.

    Pas de DELETE ici volontairement : supprimer un camion casserait
    l'historique des missions/propositions qui le référencent (mêmes
    raisons que pour Chauffeur/Mission ailleurs dans ce fichier) — on
    dispose déjà de `disponible` pour le sortir de la flotte active.
    """

    serializer_class = CamionSerializer

    permission_classes = [
        IsAuthenticated
    ]

    def get_queryset(self):

        return Camion.objects.filter(
            proprietaire=self.request.user
        )


class ChauffeurListCreateView(generics.ListCreateAPIView):
    """Les chauffeurs du transporteur connecté.

    Le transporteur est déduit de `request.user` : Flutter n'envoie jamais
    `transporteur`, exactement comme pour les camions.
    """

    serializer_class = ChauffeurSerializer

    permission_classes = [
        IsAuthenticated
    ]

    def get_queryset(self):

        return Chauffeur.objects.filter(
            transporteur=self.request.user
        ).prefetch_related(
            "affectations__camion"
        )

    def perform_create(self, serializer):

        serializer.save(
            transporteur=self.request.user
        )


class ChauffeurDetailView(generics.RetrieveUpdateDestroyAPIView):

    serializer_class = ChauffeurSerializer

    permission_classes = [
        IsAuthenticated
    ]

    lookup_url_kwarg = "id"

    def get_queryset(self):

        return Chauffeur.objects.filter(
            transporteur=self.request.user
        ).prefetch_related(
            "affectations__camion"
        )


class AffectationChauffeurListCreateView(
    generics.ListCreateAPIView
):
    """Historique des affectations camion ↔ chauffeur du transporteur.

    Filtres possibles : `?camion=<id>`, `?chauffeur=<id>`, `?active=true`.
    Créer une affectation clôture automatiquement celles qui sont encore
    ouvertes sur ce camion et sur ce chauffeur, pour respecter la règle
    "un seul camion par chauffeur à un instant donné".
    """

    serializer_class = AffectationChauffeurSerializer

    permission_classes = [
        IsAuthenticated
    ]

    def get_queryset(self):

        queryset = AffectationChauffeur.objects.filter(
            chauffeur__transporteur=self.request.user
        ).select_related(
            "chauffeur",
            "camion"
        )

        camion_id = self.request.query_params.get("camion")
        if camion_id:
            queryset = queryset.filter(camion_id=camion_id)

        chauffeur_id = self.request.query_params.get("chauffeur")
        if chauffeur_id:
            queryset = queryset.filter(chauffeur_id=chauffeur_id)

        if self.request.query_params.get("active") == "true":
            queryset = queryset.filter(date_fin__isnull=True)

        return queryset

    def perform_create(self, serializer):

        chauffeur = serializer.validated_data["chauffeur"]
        camion = serializer.validated_data["camion"]
        date_debut = serializer.validated_data.get(
            "date_debut"
        ) or timezone.now()

        with transaction.atomic():

            # On clôture l'affectation en cours plutôt que de la supprimer :
            # l'historique doit rester relisible.
            AffectationChauffeur.objects.filter(
                date_fin__isnull=True
            ).filter(
                Q(camion=camion) | Q(chauffeur=chauffeur)
            ).update(
                date_fin=date_debut
            )

            serializer.save(
                date_debut=date_debut
            )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def terminer_affectation(request, id):
    """Libère un camion : clôture l'affectation sans effacer l'historique."""

    try:
        affectation = AffectationChauffeur.objects.select_related(
            "chauffeur",
            "camion"
        ).get(
            id=id,
            chauffeur__transporteur=request.user
        )

    except AffectationChauffeur.DoesNotExist:
        return Response(
            {"message": "Affectation introuvable."},
            status=404
        )

    if not affectation.active:
        return Response(
            {"message": "Cette affectation est déjà terminée."},
            status=400
        )

    affectation.cloturer()

    return Response(
        AffectationChauffeurSerializer(affectation).data
    )


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def profil(request):

    user = request.user

    if request.method == 'PATCH':

        serializer = ProfilUpdateSerializer(
            user,
            data=request.data,
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

    return Response({

        "id": user.id,
        "username": user.username,
        "telephone": user.telephone,
        "type_compte": user.type_compte,
        "nom_entreprise": user.nom_entreprise,
        "email": user.email,
        "adresse": user.adresse,
        "pays": user.pays,
        "photo_profil": (
            request.build_absolute_uri(user.photo_profil.url)
            if user.photo_profil else None
        ),

    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def changer_mot_de_passe(request):

    user = request.user

    serializer = ChangerMotDePasseSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    ancien = serializer.validated_data['ancien_mot_de_passe']
    nouveau = serializer.validated_data['nouveau_mot_de_passe']

    if not user.check_password(ancien):
        return Response(
            {"detail": "Le mot de passe actuel est incorrect."},
            status=400,
        )

    user.set_password(nouveau)
    user.save()

    return Response(
        {"message": "Mot de passe mis à jour avec succès."}
    )


@api_view(['POST'])
def demander_reinitialisation(request):
    """Étape 1 du "mot de passe oublié" : génère un code à 6 chiffres valable
    15 minutes. Pas d'authentification requise — c'est précisément le cas où
    l'utilisateur ne peut pas se connecter.

    MODE DÉMO : aucune passerelle SMS/email n'est configurée côté backend
    (aucun EMAIL_BACKEND dans settings.py), donc le code est renvoyé
    directement dans la réponse plutôt qu'envoyé par un canal externe. À
    remplacer par un vrai envoi avant toute mise en production — tel quel,
    n'importe qui connaissant un numéro de téléphone peut réinitialiser le
    mot de passe associé.
    """

    serializer = DemandeReinitialisationSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    telephone = serializer.validated_data['telephone']

    # Comme pour la connexion, le champ ne contient pas l'indicatif : on
    # cherche par suffixe. Pas de deuxième facteur disponible à cette étape
    # pour désambiguïser une éventuelle collision entre deux pays (cas rare,
    # accepté comme limite) — `.first()` sur le seul candidat le plus probable.
    q = candidats_suffixe_telephone(telephone)
    user = User.objects.filter(q).first() if q is not None else None
    if user is None:
        return Response(
            {"detail": "Aucun compte associé à ce numéro."},
            status=404,
        )

    code = ''.join(random.choices(string.digits, k=6))

    user.code_reinitialisation = code
    user.code_reinitialisation_expiration = timezone.now() + timedelta(minutes=15)
    user.save(
        update_fields=['code_reinitialisation', 'code_reinitialisation_expiration']
    )

    return Response({
        "message": "Code de réinitialisation généré.",
        "code": code,
        "expire_dans_minutes": 15,
    })


@api_view(['POST'])
def confirmer_reinitialisation(request):
    """Étape 2 : vérifie le code (non expiré) et applique le nouveau mot de
    passe. Le code est à usage unique — effacé qu'il ait servi ou non dès
    qu'un nouveau est demandé, et systématiquement après une réinitialisation
    réussie."""

    serializer = ConfirmerReinitialisationSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data

    q = candidats_suffixe_telephone(data['telephone'])
    candidats = list(User.objects.filter(q)) if q is not None else []
    if not candidats:
        return Response(
            {"detail": "Aucun compte associé à ce numéro."},
            status=404,
        )

    # En cas de collision de suffixe (numéro local identique par coïncidence
    # dans deux pays, cas rare), le code à usage unique désambiguïse : on
    # retient le candidat dont le code correspond plutôt que le premier venu.
    user = next(
        (c for c in candidats if c.code_reinitialisation == data['code']),
        candidats[0],
    )

    if not user.code_reinitialisation or user.code_reinitialisation != data['code']:
        return Response(
            {"detail": "Code invalide."},
            status=400,
        )

    if (
        not user.code_reinitialisation_expiration
        or timezone.now() > user.code_reinitialisation_expiration
    ):
        return Response(
            {"detail": "Ce code a expiré. Demandez-en un nouveau."},
            status=400,
        )

    user.set_password(data['nouveau_mot_de_passe'])
    user.code_reinitialisation = None
    user.code_reinitialisation_expiration = None
    user.save()

    return Response(
        {"message": "Mot de passe réinitialisé avec succès."}
    )


class PropositionListCreateView(
    generics.ListCreateAPIView
):

    serializer_class = PropositionSerializer
    permission_classes = [IsAuthenticated]


    def get_queryset(self):

        user = self.request.user

        # `select_related` : le serializer déréférence `demande.pays_depart`
        # (pour `pays_depart`/`pays_arrivee`/`devise`) sur chaque ligne.
        # `prefetch_related` : PropositionCamionSerializer résout maintenant
        # la photo du camion (via `camion.images`) et celle du chauffeur pour
        # chaque ligne de `camions` — sans ça, N+1 requêtes par proposition.
        queryset = Proposition.objects.select_related('demande').prefetch_related(
            'camions__camion__images', 'camions__chauffeur'
        )

        # Transporteur : ses propositions
        if user.type_compte == "TRANSPORTEUR":

            return queryset.filter(
                transporteur=user
            )


        # Client : propositions de ses demandes
        if user.type_compte == "ENTREPRISE":

            return queryset.filter(
                demande__client=user
            )


        return queryset


    def perform_create(self, serializer):

        from django.db import IntegrityError
        from rest_framework.exceptions import ValidationError as DRFValidationError

        try:
            proposition = serializer.save(
                transporteur=self.request.user
            )
        except IntegrityError:
            # `unique_proposition_transporteur_par_demande` : un transporteur
            # ne peut proposer qu'une fois par demande. Sans ce catch,
            # l'IntegrityError de la contrainte SQLite remontait telle quelle
            # en 500 au lieu d'un message exploitable côté Flutter.
            raise DRFValidationError({
                "detail": "Vous avez déjà envoyé une proposition pour cette demande."
            })

        devise = devise_pour_pays(proposition.demande.pays_depart)

        notifier(
            proposition.demande.client,
            Notification.Type.NOUVELLE_PROPOSITION,
            f"Nouvelle proposition de {self.request.user.nom_entreprise or self.request.user.username} "
            f"pour {proposition.demande.ville_depart} → {proposition.demande.ville_arrivee} : "
            f"{proposition.prix} {devise}.",
            proposition=proposition,
        )
    



@api_view(["POST"])
@permission_classes([IsAuthenticated])
def accepter_proposition(request, id):

    try:

        proposition = Proposition.objects.get(
            id=id
        )


        mission = accepter_proposition_service(
            proposition,
            request.user
        )


        return Response({

            "message": "Mission créée",

            "mission_id": mission.id

        })


    except PermissionError as e:

        return Response(
            {
                "detail": str(e)
            },
            status=403
        )


    except ValueError as e:

        return Response(
            {
                "detail": str(e)
            },
            status=400
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def refuser_proposition(request, id):

    try:

        proposition = Proposition.objects.get(
            id=id
        )


        refuser_proposition_service(
            proposition,
            request.user
        )


        return Response({

            "message": "Proposition refusée"

        })


    except PermissionError as e:

        return Response(
            {
                "detail": str(e)
            },
            status=403
        )


    except ValueError as e:

        return Response(
            {
                "detail": str(e)
            },
            status=400
        )

class MissionListView(generics.ListAPIView):

    serializer_class = MissionSerializer
    permission_classes = [IsAuthenticated]


    def get_queryset(self):

        user = self.request.user

        # select_related / prefetch_related : le serializer expose le trajet,
        # le transporteur et les camions de chaque mission.
        queryset = Mission.objects.select_related(
            "demande",
            "transporteur",
        ).prefetch_related(
            "camions__camion__images", "camions__chauffeur"
        )


        if user.type_compte == "TRANSPORTEUR":

            return queryset.filter(
                transporteur=user
            )


        if user.type_compte == "ENTREPRISE":

            return queryset.filter(
                client=user
            )


        return Mission.objects.all()
    



class PositionGPSCreateView(
    generics.CreateAPIView
):

    serializer_class = PositionGPSSerializer
    permission_classes = [IsAuthenticated]


    def perform_create(self, serializer):

        mission_camion = serializer.validated_data['mission_camion']

        if mission_camion.mission.transporteur_id != self.request.user.id:
            raise PermissionDenied(
                "Vous n'êtes pas autorisé à mettre à jour la position de ce camion."
            )

        position = serializer.save()

        camion = mission_camion.camion

        if position.source == 'TELEPHONE' and position.telephone_chauffeur:
            camion.suivi_par_telephone = True
            camion.mode_suivi = 'TELEPHONE'
            camion.save(update_fields=['suivi_par_telephone', 'mode_suivi'])

            # C'est le téléphone du chauffeur qui sert de position au camion :
            # on met à jour le chauffeur de cette mission, pas le camion.
            # `resoudre_position_camion` ira le rechercher via l'affectation
            # active. Avant ce correctif, ce bloc écrivait sur des champs
            # `derniere_latitude/derniere_longitude/derniere_position` qui
            # n'existent pas sur `MissionCamion` : Django les acceptait
            # silencieusement et `.save()` les ignorait, la donnée était
            # perdue à chaque appel.
            if mission_camion.chauffeur_id:
                Chauffeur.objects.filter(
                    id=mission_camion.chauffeur_id
                ).update(
                    latitude=position.latitude,
                    longitude=position.longitude,
                    position_updated_at=position.date,
                )

        elif position.source == 'GPS':
            camion.latitude = position.latitude
            camion.longitude = position.longitude
            camion.position_updated_at = position.date
            camion.save(
                update_fields=['latitude', 'longitude', 'position_updated_at']
            )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def historique_positions(request, mission_camion_id):
    """Historique des pings GPS d'un camion de mission, du plus récent au
    plus ancien — alimente le bouton "Historique" du suivi GPS transporteur."""

    try:
        mission_camion = MissionCamion.objects.select_related(
            "mission"
        ).get(id=mission_camion_id)

    except MissionCamion.DoesNotExist:
        return Response(
            {"message": "Camion de mission introuvable"},
            status=404
        )

    if mission_camion.mission.transporteur_id != request.user.id:
        return Response(
            {"message": "Vous n'êtes pas autorisé à consulter cet historique."},
            status=403
        )

    positions = mission_camion.positions.order_by('-date')[:50]

    return Response(
        PositionGPSSerializer(positions, many=True).data
    )




class ChauffeurLoginView(APIView):


    def post(self, request):

        telephone = request.data.get(
            "telephone"
        )

        code = request.data.get(
            "code_acces"
        )


        # Le champ ne contient pas l'indicatif (saisi en local uniquement) alors
        # que `telephone` est stocké en E.164 : on cherche par suffixe. Pas
        # besoin de boucle de désambiguïsation comme pour User (la combinaison
        # suffixe+code_acces+actif suffit déjà à isoler un seul chauffeur, un
        # code d'accès partagé par coïncidence entre deux pays étant
        # infinitésimalement improbable en plus d'une collision de numéro).
        q = candidats_suffixe_telephone(telephone)
        chauffeur = (
            Chauffeur.objects.filter(q, code_acces=code, actif=True).first()
            if q is not None else None
        )

        if chauffeur is None:

            return Response(
                {
                    "message":
                    "Identifiants incorrects"
                },
                status=401
            )


        return Response({

            "message":
            "Connexion réussie",

            "chauffeur_id":
            chauffeur.id,

            "nom":
            chauffeur.nom,

            "photo": (
                request.build_absolute_uri(chauffeur.photo.url)
                if chauffeur.photo else None
            ),

        })
    


class ChauffeurPositionView(APIView):
    """Ping de position du téléphone du chauffeur.

    Ouvert par `chauffeur_id`, sans JWT, comme `ChauffeurMissionsView` — les
    comptes chauffeur n'ont pas de token aujourd'hui, ce n'est pas cette vue
    qui change ce modèle d'auth. Indépendant de toute mission : c'est ce qui
    permet à un camion redevenu disponible sans mission active de rester
    localisable via le chauffeur qui lui est affecté.
    """

    def post(self, request, chauffeur_id):

        try:
            chauffeur = Chauffeur.objects.get(id=chauffeur_id)
        except Chauffeur.DoesNotExist:
            return Response(
                {"message": "Chauffeur introuvable."},
                status=404
            )

        serializer = ChauffeurPositionSerializer(
            chauffeur,
            data=request.data,
            partial=False
        )
        serializer.is_valid(raise_exception=True)

        serializer.save(
            position_updated_at=timezone.now()
        )

        return Response(serializer.data)


class ChauffeurPhotoView(APIView):
    """Le chauffeur met à jour sa propre photo depuis son tableau de bord.

    Ouvert par `chauffeur_id`, sans JWT, comme `ChauffeurPositionView` et
    `ChauffeurMissionsView` — les comptes chauffeur n'ont pas de token
    aujourd'hui, ce n'est pas cette vue qui change ce modèle d'auth.
    `ChauffeurPhotoSerializer` ne connaît que `photo` : impossible via cette
    route de toucher `actif`/`code_acces`/etc., réservés à
    `ChauffeurDetailView` (JWT transporteur).
    """

    def patch(self, request, chauffeur_id):

        try:
            chauffeur = Chauffeur.objects.get(id=chauffeur_id)
        except Chauffeur.DoesNotExist:
            return Response(
                {"message": "Chauffeur introuvable."},
                status=404
            )

        serializer = ChauffeurPhotoSerializer(
            chauffeur,
            data=request.data,
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response({
            "id": chauffeur.id,
            "photo": (
                request.build_absolute_uri(chauffeur.photo.url)
                if chauffeur.photo else None
            ),
        })


class ChauffeurMissionsView(APIView):


    def get(self, request, chauffeur_id):

        missions = MissionCamion.objects.filter(
            chauffeur_id=chauffeur_id
        ).select_related(
            "mission",
            "mission__demande",
            "mission__client",
            "camion"
        )


        serializer = ChauffeurMissionSerializer(
            missions,
            many=True
        )


        return Response(
            serializer.data
        )


@api_view(['POST'])
def chauffeur_demarrer_mission(request, chauffeur_id, mission_id):
    """Équivalent de `accepter_mission` mais déclenché par le chauffeur
    lui-même depuis son tableau de bord : ouvert par `chauffeur_id`/`mission_id`
    (pas de JWT côté chauffeur), l'appartenance remplace la vérification
    `mission.transporteur_id == request.user.id` — le chauffeur doit être
    affecté à un `MissionCamion` de cette mission."""

    try:
        mission = Mission.objects.select_related(
            "demande", "client", "transporteur"
        ).get(id=mission_id)
    except Mission.DoesNotExist:
        return Response({"message": "Mission introuvable"}, status=404)

    if not mission.camions.filter(chauffeur_id=chauffeur_id).exists():
        return Response(
            {"message": "Vous n'êtes pas affecté à cette mission."},
            status=403
        )

    try:
        demarrer_mission_service(mission)
    except ValueError as e:
        return Response({"message": str(e)}, status=400)

    # `demarrer_mission_service` ne notifie que le client (comportement
    # partagé avec `accepter_mission`, où l'acteur est déjà le transporteur —
    # se notifier soi-même n'aurait pas de sens). Ici l'acteur est le
    # chauffeur : le transporteur doit être prévenu séparément, lui qui ne
    # verrait sinon le changement qu'en rafraîchissant manuellement.
    notifier(
        mission.transporteur,
        Notification.Type.MISSION_DEMARREE,
        f"Le chauffeur a démarré la mission {mission.demande.ville_depart} → {mission.demande.ville_arrivee}."
    )

    return Response({"message": "Mission démarrée", "mission": mission.id})


@api_view(['POST'])
def chauffeur_terminer_mission(request, chauffeur_id, mission_id):
    """Équivalent chauffeur de `terminer_mission` — voir
    `chauffeur_demarrer_mission` pour le modèle d'autorisation."""

    try:
        mission = Mission.objects.select_related(
            "demande", "client", "transporteur"
        ).get(id=mission_id)
    except Mission.DoesNotExist:
        return Response({"message": "Mission introuvable"}, status=404)

    if not mission.camions.filter(chauffeur_id=chauffeur_id).exists():
        return Response(
            {"message": "Vous n'êtes pas affecté à cette mission."},
            status=403
        )

    if mission.statut != Mission.Statut.EN_COURS:
        return Response(
            {"message": "Cette mission ne peut pas être terminée."},
            status=400
        )

    terminer_mission_service(mission)

    notifier(
        mission.transporteur,
        Notification.Type.MISSION_TERMINEE,
        f"Le chauffeur a terminé la mission {mission.demande.ville_depart} → {mission.demande.ville_arrivee}."
    )

    return Response({"message": "Mission terminée", "mission": mission.id})





class TransporteurDashboardView(APIView):

    permission_classes = [
        IsAuthenticated
    ]


    def get(self, request):

        transporteur = request.user



        # ==========================
        # CAMIONS
        # ==========================

        camions = Camion.objects.filter(
            proprietaire=transporteur
        )


        camions_total = camions.count()


        camions_disponibles = camions.filter(
            disponible=True
        ).count()


        camions_en_mission = camions.filter(
            disponible=False
        ).count()


        # À développer avec système maintenance
        camions_maintenance = 0

        camions_hors_service = 0





        # ==========================
        # CHAUFFEURS
        # ==========================

        chauffeurs = Chauffeur.objects.filter(
            transporteur=transporteur
        )


        chauffeurs_total = chauffeurs.count()


        chauffeurs_disponibles = chauffeurs.filter(
            disponible=True
        ).count()


        chauffeurs_en_mission = (
            chauffeurs_total -
            chauffeurs_disponibles
        )





        # ==========================
        # MISSIONS
        # ==========================

        missions = Mission.objects.filter(
            transporteur=transporteur
        )


        missions_planifiees = missions.filter(
            statut="PLANIFIEE"
        ).count()


        missions_en_cours = missions.filter(
            statut="EN_COURS"
        ).count()


        missions_terminees = missions.filter(
            statut="TERMINEE"
        ).count()


        missions_annulees = missions.filter(
            statut="ANNULEE"
        ).count()



        aujourd_hui = timezone.now().date()


        missions_aujourdhui = missions.filter(
            date_creation__date=aujourd_hui
        ).count()





        # ==========================
        # REVENUS
        # ==========================
        #
        # Ventilés par devise (dérivée de demande.pays_depart) plutôt que
        # sommés en SQL : un transporteur CEDEAO peut avoir des missions
        # terminées dans plusieurs pays/devises. Cf. revenus_par_devise().

        revenus = revenus_par_devise(
            missions.filter(
                statut="TERMINEE"
            )
        )



        debut_mois = aujourd_hui.replace(
            day=1
        )


        revenus_mois = revenus_par_devise(
            missions.filter(
                statut="TERMINEE",
                date_creation__date__gte=debut_mois
            )
        )




        debut_annee = aujourd_hui.replace(
            month=1,
            day=1
        )


        revenus_annee = revenus_par_devise(
            missions.filter(
                statut="TERMINEE",
                date_creation__date__gte=debut_annee
            )
        )





        # ==========================
        # PROPOSITIONS
        # ==========================

        propositions_en_attente = Proposition.objects.filter(
            transporteur=transporteur,
            statut="EN_ATTENTE"
        ).count()





        # ==========================
        # DEMANDES DISPONIBLES
        # ==========================

        demandes_disponibles = DemandeTransport.objects.filter(
            statut="OUVERTE"
        ).count()





        # ==========================
        # NOTIFICATIONS
        # ==========================

        notifications_non_lues = Notification.objects.filter(
            destinataire=transporteur,
            lue=False
        ).count()





        # ==========================
        # DATA
        # ==========================

        data = {


            # CAMIONS

            "camions_total":
                camions_total,


            "camions_disponibles":
                camions_disponibles,


            "camions_en_mission":
                camions_en_mission,


            "camions_maintenance":
                camions_maintenance,


            "camions_hors_service":
                camions_hors_service,



            # CHAUFFEURS

            "chauffeurs_total":
                chauffeurs_total,


            "chauffeurs_disponibles":
                chauffeurs_disponibles,


            "chauffeurs_en_mission":
                chauffeurs_en_mission,



            # MISSIONS

            "missions_planifiees":
                missions_planifiees,


            "missions_en_cours":
                missions_en_cours,


            "missions_terminees":
                missions_terminees,


            "missions_annulees":
                missions_annulees,


            "missions_aujourdhui":
                missions_aujourdhui,



            # DEMANDES

            "demandes_disponibles":
                demandes_disponibles,


            "propositions_en_attente":
                propositions_en_attente,



            # FINANCES

            "revenus":
                revenus,


            "revenus_mois":
                revenus_mois,


            "revenus_annee":
                revenus_annee,



            # NOTIFICATIONS

            "notifications_non_lues":
                notifications_non_lues

        }




        serializer = TransporteurDashboardSerializer(
            data
        )


        return Response(
            serializer.data
        )


class ClientDashboardView(APIView):
    """Statistiques du compte ENTREPRISE (client) connecté — pendant client de
    TransporteurDashboardView (même structure : scoping implicite via les FK,
    pas de contrôle de type_compte explicite)."""

    permission_classes = [
        IsAuthenticated
    ]

    def get(self, request):

        client = request.user


        # ==========================
        # DEMANDES
        # ==========================

        demandes = DemandeTransport.objects.filter(client=client)

        demandes_total = demandes.count()

        demandes_ouvertes = demandes.filter(statut="OUVERTE").count()

        demandes_en_cours = demandes.filter(statut="EN_COURS").count()

        demandes_terminees = demandes.filter(statut="TERMINEE").count()

        demandes_annulees = demandes.filter(statut="ANNULEE").count()


        # ==========================
        # MISSIONS
        # ==========================

        missions = Mission.objects.filter(client=client)

        missions_total = missions.count()

        missions_en_cours = missions.filter(
            statut=Mission.Statut.EN_COURS
        ).count()

        missions_terminees = missions.filter(
            statut=Mission.Statut.TERMINEE
        ).count()


        # ==========================
        # PROPOSITIONS
        # ==========================

        propositions_en_attente = Proposition.objects.filter(
            demande__client=client,
            statut="EN_ATTENTE"
        ).count()


        # ==========================
        # DEPENSES
        # ==========================
        #
        # Ventilées par devise (dérivée de demande.pays_depart) plutôt que
        # sommées en SQL : un client CEDEAO peut avoir des missions
        # terminées dans plusieurs pays/devises. Cf. revenus_par_devise().

        aujourd_hui = timezone.now().date()

        debut_mois = aujourd_hui.replace(day=1)

        depenses_total = revenus_par_devise(
            missions.filter(
                statut=Mission.Statut.TERMINEE
            )
        )

        depenses_mois = revenus_par_devise(
            missions.filter(
                statut=Mission.Statut.TERMINEE,
                date_creation__date__gte=debut_mois
            )
        )


        # ==========================
        # NOTIFICATIONS
        # ==========================

        notifications_non_lues = Notification.objects.filter(
            destinataire=client,
            lue=False
        ).count()


        data = {

            "demandes_total": demandes_total,
            "demandes_ouvertes": demandes_ouvertes,
            "demandes_en_cours": demandes_en_cours,
            "demandes_terminees": demandes_terminees,
            "demandes_annulees": demandes_annulees,

            "missions_total": missions_total,
            "missions_en_cours": missions_en_cours,
            "missions_terminees": missions_terminees,

            "propositions_en_attente": propositions_en_attente,

            "depenses_total": depenses_total,
            "depenses_mois": depenses_mois,

            "notifications_non_lues": notifications_non_lues,

        }

        serializer = ClientDashboardSerializer(data)

        return Response(serializer.data)


class AdminDashboardView(APIView):
    """Statistiques globales de la plateforme (tous transporteurs et
    entreprises confondus), réservées aux comptes ADMIN."""

    permission_classes = [
        IsAuthenticated
    ]

    def get(self, request):

        if request.user.type_compte != "ADMIN":
            return Response(
                {"message": "Accès réservé aux administrateurs."},
                status=403
            )

        # Ventilé par devise (dérivée de demande.pays_depart) plutôt que
        # sommé en SQL : la plateforme a des missions terminées dans
        # plusieurs pays CEDEAO, donc plusieurs devises. Cf. services.py.
        revenus_total = revenus_par_devise(
            Mission.objects.filter(
                statut=Mission.Statut.TERMINEE
            )
        )

        data = {

            "transporteurs_total": User.objects.filter(
                type_compte="TRANSPORTEUR"
            ).count(),

            "entreprises_total": User.objects.filter(
                type_compte="ENTREPRISE"
            ).count(),

            "chauffeurs_total": Chauffeur.objects.count(),

            "camions_total": Camion.objects.count(),

            "camions_disponibles": Camion.objects.filter(
                disponible=True
            ).count(),

            "missions_total": Mission.objects.count(),

            "missions_en_cours": Mission.objects.filter(
                statut=Mission.Statut.EN_COURS
            ).count(),

            "missions_terminees": Mission.objects.filter(
                statut=Mission.Statut.TERMINEE
            ).count(),

            "demandes_ouvertes": DemandeTransport.objects.filter(
                statut="OUVERTE"
            ).count(),

            "revenus_total": revenus_total,

        }

        serializer = AdminDashboardSerializer(data)

        return Response(serializer.data)


class NotificationListView(generics.ListAPIView):
    """Notifications internes de l'utilisateur connecté, les plus récentes
    d'abord (cf. `Notification.Meta.ordering`)."""

    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(
            destinataire=self.request.user
        ).select_related('proposition__demande')


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def marquer_notification_lue(request, id):

    try:
        notification = Notification.objects.get(
            id=id,
            destinataire=request.user
        )

    except Notification.DoesNotExist:
        return Response(
            {"message": "Notification introuvable."},
            status=404
        )

    notification.lue = True
    notification.save(update_fields=["lue"])

    return Response(NotificationSerializer(notification).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def marquer_toutes_notifications_lues(request):

    Notification.objects.filter(
        destinataire=request.user,
        lue=False
    ).update(lue=True)

    return Response({"message": "Toutes les notifications ont été marquées comme lues."})