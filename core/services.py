import math
from datetime import timedelta
from decimal import Decimal

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from .constants import devise_pour_pays
from .gateway_paiement import get_gateway
from .models import (
    Camion,
    Litige,
    Notification,
    Paiement,
    PreuvePaiement,
    Proposition,
    PropositionCamion,
    Mission,
    MissionCamion,
    User,
)


# ==========================
# NOTIFICATIONS
# ==========================

def notifier(destinataire, type_notification, message, proposition=None, paiement=None):
    """Crée une notification interne. `destinataire=None` ne fait rien —
    évite un `if` à chaque appel quand la relation (ex. chauffeur d'une
    proposition) peut être absente.

    `proposition` : lien vers la Proposition concernée (types NOUVELLE_
    PROPOSITION/PROPOSITION_ACCEPTEE/PROPOSITION_REFUSEE) — sans ce lien,
    `message` est un texte figé qui peut afficher un prix différent de celui
    de la proposition telle qu'elle existe (ou plus) au moment où
    l'utilisateur consulte ses notifications.

    `paiement` : même principe pour les types PAIEMENT_*/LITIGE_*."""
    if destinataire is None:
        return None

    return Notification.objects.create(
        destinataire=destinataire,
        type_notification=type_notification,
        message=message,
        proposition=proposition,
        paiement=paiement,
    )


# ==========================
# POSITION : résolution et fraîcheur
# ==========================
#
# Seuils de fraîcheur d'une position GPS (ajustables). Au-delà de
# FRAICHEUR_A_VERIFIER, on considère la position comme ancienne mais on la
# renvoie quand même : mieux vaut une vieille position que rien.
FRAICHEUR_TRES_FIABLE = timedelta(minutes=2)
FRAICHEUR_FIABLE = timedelta(minutes=10)
FRAICHEUR_A_VERIFIER = timedelta(minutes=30)

# Bonus/malus de score appliqué au classement de RechercheCamionView selon la
# fraîcheur de la position résolue d'un camion. `historique`/`fiabilité`
# (mentionnés comme facteurs possibles) n'ont pas de source de données
# aujourd'hui — pas de modèle de suivi de fiabilité par camion/chauffeur —
# et ne sont donc pas inclus ici.
BONUS_FRAICHEUR = {
    'TRES_FIABLE': 5,
    'FIABLE': 2,
    'A_VERIFIER': 0,
    'ANCIENNE': -3,
    'INCONNUE': -5,
}


def classifier_fraicheur(updated_at):
    """Classe une position selon son ancienneté par rapport à maintenant.

    `updated_at=None` (position statique jamais rapportée) -> 'INCONNUE'.
    """
    if updated_at is None:
        return 'INCONNUE'

    age = timezone.now() - updated_at

    if age <= FRAICHEUR_TRES_FIABLE:
        return 'TRES_FIABLE'
    if age <= FRAICHEUR_FIABLE:
        return 'FIABLE'
    if age <= FRAICHEUR_A_VERIFIER:
        return 'A_VERIFIER'
    return 'ANCIENNE'


def distance_km(lat1, lon1, lat2, lon2):
    """Distance à vol d'oiseau (Haversine), en kilomètres.

    Pas de dépendance externe : la base de dev est SQLite, sans PostGIS.
    """
    rayon_terre_km = 6371.0

    lat1, lon1, lat2, lon2 = (
        math.radians(float(lat1)),
        math.radians(float(lon1)),
        math.radians(float(lat2)),
        math.radians(float(lon2)),
    )

    delta_lat = lat2 - lat1
    delta_lon = lon2 - lon1

    a = (
        math.sin(delta_lat / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin(delta_lon / 2) ** 2
    )
    c = 2 * math.asin(math.sqrt(a))

    return rayon_terre_km * c


def resoudre_position_camion(camion):
    """Détermine la position actuelle la plus fiable d'un camion.

    Priorité :
    1. Position propre du camion, si elle a déjà été rapportée (`position_updated_at`
       renseigné) — réservé à un futur boîtier GPS embarqué, rien ne l'alimente
       aujourd'hui mais la logique lui laisse la priorité si elle existe un jour.
    2. Position du chauffeur actuellement affecté à ce camion (`chauffeur_actuel`),
       s'il a déjà rapporté une position.
    3. Valeur statique du camion (latitude/longitude sans `position_updated_at`),
       fraîcheur 'INCONNUE'.
    4. `None` si aucune donnée n'existe.

    Retourne un dict {latitude, longitude, source, updated_at, fraicheur} ou None.
    """
    if camion.latitude is not None and camion.longitude is not None:
        if camion.position_updated_at is not None:
            return {
                'latitude': camion.latitude,
                'longitude': camion.longitude,
                'source': 'CAMION',
                'updated_at': camion.position_updated_at,
                'fraicheur': classifier_fraicheur(camion.position_updated_at),
            }

    chauffeur = camion.chauffeur_actuel
    if (
        chauffeur is not None
        and chauffeur.latitude is not None
        and chauffeur.longitude is not None
    ):
        return {
            'latitude': chauffeur.latitude,
            'longitude': chauffeur.longitude,
            'source': 'CHAUFFEUR',
            'updated_at': chauffeur.position_updated_at,
            'fraicheur': classifier_fraicheur(chauffeur.position_updated_at),
        }

    if camion.latitude is not None and camion.longitude is not None:
        return {
            'latitude': camion.latitude,
            'longitude': camion.longitude,
            'source': 'INCONNUE',
            'updated_at': None,
            'fraicheur': 'INCONNUE',
        }

    return None


# ==========================
# FINANCES : ventilation par devise
# ==========================
#
# La devise d'une Mission n'est pas un champ stocké : elle se dérive de
# `demande.pays_depart` via `devise_pour_pays` (cf. constants.py), pour ne
# pas créer une deuxième source de vérité. Depuis le passage au périmètre
# CEDEAO, un même transporteur (et a fortiori la plateforme entière) peut
# avoir des missions terminées dans plusieurs pays/devises : un simple
# `.aggregate(Sum("prix_final"))` mélangerait alors XOF, GHS, NGN... sans
# avertissement. On regroupe donc en Python après avoir récupéré
# (prix_final, pays_depart) en une seule requête.

def revenus_par_devise(missions):
    """Ventile `prix_final` d'un queryset de Mission par devise.

    Retourne une liste de {"devise": str, "montant": float} triée par
    montant décroissant (index 0 = devise dominante), ou [] si `missions`
    ne contient aucune ligne.
    """
    totaux = {}

    for prix_final, pays_depart in missions.values_list(
        "prix_final", "demande__pays_depart"
    ):
        devise = devise_pour_pays(pays_depart)
        totaux[devise] = totaux.get(devise, 0.0) + float(prix_final or 0)

    return sorted(
        (
            {"devise": devise, "montant": montant}
            for devise, montant in totaux.items()
        ),
        key=lambda entree: entree["montant"],
        reverse=True,
    )


@transaction.atomic
def demarrer_mission_service(mission):
    """PLANIFIEE -> EN_COURS : bloque le(s) camion(s)/chauffeur(s) qui
    participent à la mission. Partagé entre `accepter_mission` (transporteur,
    JWT) et `chauffeur_demarrer_mission` (chauffeur, ouvert par id) — les
    deux vues font leur propre vérification de propriété/appartenance avant
    d'appeler ceci, qui ne revérifie que le statut."""

    if mission.statut != Mission.Statut.PLANIFIEE:
        raise ValueError("Cette mission ne peut plus être démarrée.")

    mission.statut = Mission.Statut.EN_COURS
    if mission.date_depart is None:
        mission.date_depart = timezone.now()
    mission.save()

    for mission_camion in mission.camions.select_related("camion", "chauffeur"):

        mission_camion.camion.disponible = False
        mission_camion.camion.save(update_fields=["disponible"])

        if mission_camion.chauffeur_id:
            mission_camion.chauffeur.disponible = False
            mission_camion.chauffeur.save(update_fields=["disponible"])

    notifier(
        mission.client,
        Notification.Type.MISSION_DEMARREE,
        f"Votre mission {mission.demande.ville_depart} → {mission.demande.ville_arrivee} a démarré."
    )

    return mission


@transaction.atomic
def terminer_mission_service(mission):
    """EN_COURS (ou toute mission non close) -> TERMINEE : libère le(s)
    camion(s)/chauffeur(s), sans toucher l'affectation chauffeur ↔ camion —
    le chauffeur reste associé à son camion, c'est cette affectation qui
    permet de continuer à localiser le camion via son téléphone une fois la
    mission terminée. Partagé entre `terminer_mission` (transporteur, JWT)
    et `chauffeur_terminer_mission` (chauffeur, ouvert par id)."""

    mission.statut = Mission.Statut.TERMINEE
    if mission.date_arrivee is None:
        mission.date_arrivee = timezone.now()
    mission.save()

    mission.demande.statut = "TERMINEE"
    mission.demande.save(update_fields=["statut"])

    for mission_camion in mission.camions.select_related("camion", "chauffeur"):

        mission_camion.camion.disponible = True
        mission_camion.camion.save(update_fields=["disponible"])

        if mission_camion.chauffeur_id:
            mission_camion.chauffeur.disponible = True
            mission_camion.chauffeur.save(update_fields=["disponible"])

    notifier(
        mission.client,
        Notification.Type.MISSION_TERMINEE,
        f"Votre mission {mission.demande.ville_depart} → {mission.demande.ville_arrivee} est terminée."
    )

    # Additif : libère les fonds séquestrés si un paiement sécurisé existe
    # pour cette mission. `liberer_paiement_service` est un no-op silencieux
    # sans Paiement (mission sans paiement — cas normal pour toute mission
    # créée avant ce module, ou dont le client n'a pas encore payé) : cet
    # appel ne peut donc pas casser la clôture de mission existante.
    liberer_paiement_service(mission)

    return mission


@transaction.atomic
def accepter_proposition_service(proposition, user):

    # Vérification propriétaire de la demande

    if proposition.demande.client != user:
        raise PermissionError(
            "Vous n'avez pas le droit d'accepter cette proposition."
        )


    # Vérifier le statut

    if proposition.statut != "EN_ATTENTE":
        raise ValueError(
            "Cette proposition ne peut plus être acceptée."
        )


    # Accepter la proposition

    proposition.statut = "ACCEPTEE"
    proposition.save()

    trajet = f"{proposition.demande.ville_depart} → {proposition.demande.ville_arrivee}"

    notifier(
        proposition.transporteur,
        Notification.Type.PROPOSITION_ACCEPTEE,
        f"Votre proposition pour {trajet} a été acceptée.",
        proposition=proposition,
    )


    # Refuser les autres propositions — notifier chaque transporteur avant
    # le UPDATE en masse, qui ne redéclenche aucun signal.

    autres_propositions = Proposition.objects.filter(
        demande=proposition.demande
    ).exclude(
        id=proposition.id
    ).select_related('transporteur')

    for autre in autres_propositions:
        notifier(
            autre.transporteur,
            Notification.Type.PROPOSITION_REFUSEE,
            f"Votre proposition pour {trajet} n'a pas été retenue.",
            proposition=autre,
        )

    autres_propositions.update(
        statut="REFUSEE"
    )


    # La demande n'était plus "en marché" : sans ce changement de statut,
    # `DemandeTransportListCreateView.get_queryset` (filtré sur statut=
    # "OUVERTE" côté transporteur) continuait à la lister indéfiniment,
    # bouton "Proposer" inclus, alors qu'une mission existait déjà dessus.
    proposition.demande.statut = "EN_COURS"
    proposition.demande.save(update_fields=["statut"])


    # Création de la mission

    mission = Mission.objects.create(

        demande=proposition.demande,

        proposition=proposition,

        client=proposition.demande.client,

        transporteur=proposition.transporteur,

        prix_final=proposition.prix

    )

    notifier(
        mission.client,
        Notification.Type.MISSION_CREEE,
        f"Une mission a été créée pour {trajet}."
    )


    # Création des camions de mission

    for proposition_camion in proposition.camions.all():

        MissionCamion.objects.create(

            mission=mission,

            camion=proposition_camion.camion,

            chauffeur=proposition_camion.chauffeur

        )


        # Bloquer le camion

        proposition_camion.camion.disponible = False
        proposition_camion.camion.save()


        # Bloquer le chauffeur

        if proposition_camion.chauffeur:

            proposition_camion.chauffeur.disponible = False

            proposition_camion.chauffeur.save()


    return mission


@transaction.atomic
def refuser_proposition_service(proposition, user):

    # Vérification propriétaire de la demande

    if proposition.demande.client != user:
        raise PermissionError(
            "Vous n'avez pas le droit de refuser cette proposition."
        )


    # Vérifier le statut

    if proposition.statut != "EN_ATTENTE":
        raise ValueError(
            "Cette proposition ne peut plus être refusée."
        )


    proposition.statut = "REFUSEE"
    proposition.save()

    trajet = f"{proposition.demande.ville_depart} → {proposition.demande.ville_arrivee}"

    notifier(
        proposition.transporteur,
        Notification.Type.PROPOSITION_REFUSEE,
        f"Votre proposition pour {trajet} n'a pas été retenue.",
        proposition=proposition,
    )

    return proposition


@transaction.atomic
def proposer_camions_pour_demande(demande):
    """Crée une proposition automatique avec un matching basé sur la ville, le type de camion et la disponibilité."""
    candidats = list(
        Camion.objects.filter(
            disponible=True,
            type_camion=demande.type_camion,
        ).exclude(
            missions__isnull=False,
        ).select_related('proprietaire')
    )

    if not candidats:
        return None

    def score_camion(camion):
        score = 0
        if camion.ville and demande.ville_depart and camion.ville.lower() == demande.ville_depart.lower():
            score += 200
        if camion.ville and demande.ville_arrivee and camion.ville.lower() == demande.ville_arrivee.lower():
            score += 50
        # Bonus/malus pays : un camion dans le bon pays de départ dépasse un
        # camion dans une ville homonyme mais du mauvais pays (200-100=100 <
        # 200+100=300). Pas de filtrage dur : le transport transfrontalier
        # est le cas normal d'une appli sous-régionale, pas une exception.
        if camion.pays == demande.pays_depart:
            score += 100
        else:
            score -= 100
        if camion.pays == demande.pays_arrivee:
            score += 25
        if camion.disponible:
            score += 20
        if camion.suivi_par_telephone:
            score += 10
        # Bonus, pas filtre dur : une demande qui précise un format (ex.
        # "40 pieds") doit favoriser un camion qui correspond exactement,
        # sans pour autant exclure les autres candidats du même type — sinon
        # `candidats` pourrait devenir vide et l'auto-matching renoncerait à
        # proposer quoi que ce soit alors qu'un camion du bon type existe.
        if demande.format_camion and camion.format_camion == demande.format_camion:
            score += 75
        return score

    candidats = sorted(candidats, key=score_camion, reverse=True)

    meilleur_camion = candidats[0]
    transporteur = meilleur_camion.proprietaire

    proposition = Proposition.objects.create(
        demande=demande,
        transporteur=transporteur,
        prix=demande.prix_propose or 0,
        message=f"Proposition automatique basée sur la ville de départ {demande.ville_depart} et le type de camion demandé.",
        statut='EN_ATTENTE',
        score_matching=score_camion(meilleur_camion),
    )

    PropositionCamion.objects.create(
        proposition=proposition,
        camion=meilleur_camion,
        ordre=1,
    )

    notifier(
        transporteur,
        Notification.Type.NOUVELLE_DEMANDE,
        f"Nouvelle demande {demande.ville_depart} → {demande.ville_arrivee} : "
        f"une proposition automatique a été envoyée pour {meilleur_camion.immatriculation}.",
        proposition=proposition,
    )

    # Sans ce notifier, l'entreprise n'apprenait jamais qu'une proposition
    # existait déjà pour sa demande fraîchement créée : seul le transporteur
    # était notifié ci-dessus. Contrairement à PropositionListCreateView.
    # perform_create (proposition envoyée manuellement par un transporteur),
    # ce chemin de création automatique oubliait ce second notifier — même
    # format de message que là-bas, pour rester cohérent des deux côtés.
    devise = devise_pour_pays(demande.pays_depart)

    notifier(
        demande.client,
        Notification.Type.NOUVELLE_PROPOSITION,
        f"Nouvelle proposition de {transporteur.nom_entreprise or transporteur.username} "
        f"pour {demande.ville_depart} → {demande.ville_arrivee} : "
        f"{proposition.prix} {devise}.",
        proposition=proposition,
    )

    return proposition


# ==========================
# PAIEMENTS
# ==========================
#
# Un seul Paiement par Mission (OneToOne, cf. models.py), CARTE ou MANUEL,
# qui converge vers le même séquestre après encaissement :
#   EN_ATTENTE -> ENCAISSE -> SECURISE -> LIBERE -> VERSE
#                                  \-> REMBOURSE
# `liberer_paiement_service`/`rembourser_paiement_service` sont appelés
# depuis les points de sortie de mission déjà existants (terminer_mission_
# service ci-dessus, et la vue `refuser_mission` pour l'annulation) : ce sont
# les deux seuls endroits où une mission quitte son cycle actif, donc deux
# points d'accroche suffisent à couvrir tous les chemins (transporteur ET
# chauffeur pour la terminaison). Les deux fonctions sont des no-op
# silencieux si la mission n'a pas de Paiement, pour ne jamais faire échouer
# ces vues existantes sur une mission qui n'a pas encore de paiement.

def calculer_commission(montant_total, taux=None):
    """(commission_montant, montant_transporteur) pour un montant total et un
    taux en % (`settings.COMMISSION_AFRIFLOTTE_TAUX` si `taux` omis)."""
    if taux is None:
        taux = settings.COMMISSION_AFRIFLOTTE_TAUX

    montant_total = Decimal(str(montant_total))
    taux = Decimal(str(taux))

    commission_montant = (montant_total * taux / Decimal('100')).quantize(Decimal('0.01'))
    montant_transporteur = montant_total - commission_montant

    return commission_montant, montant_transporteur


@transaction.atomic
def creer_paiement_service(mission, mode, user):
    """Crée le Paiement (EN_ATTENTE) d'une mission. Une seule fois par
    mission (OneToOne côté modèle) — seul le client de la mission peut
    choisir comment il paie."""
    if mission.client_id != user.id:
        raise PermissionError("Vous n'avez pas le droit de payer cette mission.")

    if mode not in Paiement.Mode.values:
        raise ValueError("Mode de paiement invalide.")

    if Paiement.objects.filter(mission=mission).exists():
        raise ValueError("Cette mission a déjà un paiement associé.")

    if mission.prix_final is None:
        raise ValueError("Cette mission n'a pas de prix à payer.")

    taux = settings.COMMISSION_AFRIFLOTTE_TAUX
    commission_montant, montant_transporteur = calculer_commission(mission.prix_final, taux)

    return Paiement.objects.create(
        mission=mission,
        mode=mode,
        montant_total=mission.prix_final,
        devise=devise_pour_pays(mission.demande.pays_depart),
        commission_taux=taux,
        commission_montant=commission_montant,
        montant_transporteur=montant_transporteur,
    )


@transaction.atomic
def initier_paiement_carte_service(paiement):
    """Crée la transaction côté passerelle (simulateur par défaut, cf.
    gateway_paiement.py). La confirmation réelle arrive plus tard via
    `confirmer_paiement_carte_service` (webhook) — cette fonction ne fait que
    démarrer la transaction et retenir sa référence."""
    if paiement.mode != Paiement.Mode.CARTE:
        raise ValueError("Ce paiement n'est pas en mode carte.")
    if paiement.statut != Paiement.Statut.EN_ATTENTE:
        raise ValueError("Ce paiement a déjà été initié.")

    transaction_psp = get_gateway().creer_transaction(paiement)

    paiement.reference_externe = transaction_psp["reference"]
    paiement.save(update_fields=["reference_externe", "updated_at"])

    return transaction_psp


@transaction.atomic
def confirmer_paiement_carte_service(reference, statut_psp, carte_info=None):
    """Appelé par le webhook PSP ou par `confirmer_paiement_carte`
    (`core/views.py`, formulaire intégré côté Flutter) avec `statut_psp` =
    "REUSSI"/"ECHEC"/"EN_ATTENTE" (les 3 valeurs possibles de
    `GatewayPaiement.verifier_transaction`). Un paiement carte confirmé passe
    directement ENCAISSE -> SECURISE : le PSP a déjà vérifié la transaction,
    contrairement au mode manuel qui exige une validation admin séparée (cf.
    valider_paiement_manuel_service).

    `carte_info` (optionnel) : `{"marque", "dernier4", "expiration"}` —
    métadonnées d'affichage seulement, enregistrées uniquement si la
    transaction réussit. Le webhook PSP n'a pas ces informations (c'est
    l'app qui les détient), d'où le défaut `None`."""
    try:
        paiement = Paiement.objects.select_related(
            'mission__client', 'mission__transporteur', 'mission__demande'
        ).get(reference_externe=reference, mode=Paiement.Mode.CARTE)
    except Paiement.DoesNotExist:
        raise ValueError("Transaction introuvable.")

    if paiement.statut != Paiement.Statut.EN_ATTENTE:
        return paiement

    # "EN_ATTENTE" (PSP asynchrone, ex. PayDunya avant que le client n'ait
    # terminé sa page de paiement) n'est pas un échec — rien à faire, le
    # prochain webhook ou sondage retentera la vérification.
    if statut_psp == "EN_ATTENTE":
        return paiement

    trajet = f"{paiement.mission.demande.ville_depart} → {paiement.mission.demande.ville_arrivee}"

    if statut_psp != "REUSSI":
        paiement.statut = Paiement.Statut.ECHEC
        paiement.save(update_fields=["statut", "updated_at"])
        notifier(
            paiement.mission.client,
            Notification.Type.PAIEMENT_ECHEC,
            f"Le paiement de votre mission {trajet} a échoué.",
            paiement=paiement,
        )
        return paiement

    maintenant = timezone.now()
    paiement.statut = Paiement.Statut.SECURISE
    paiement.date_encaissement = maintenant
    paiement.date_securisation = maintenant
    champs_modifies = ["statut", "date_encaissement", "date_securisation", "updated_at"]

    if carte_info:
        paiement.carte_marque = carte_info.get("marque", "") or ""
        paiement.carte_dernier4 = carte_info.get("dernier4", "") or ""
        paiement.carte_expiration = carte_info.get("expiration", "") or ""
        champs_modifies += ["carte_marque", "carte_dernier4", "carte_expiration"]

    paiement.save(update_fields=champs_modifies)

    notifier(
        paiement.mission.client,
        Notification.Type.PAIEMENT_SECURISE,
        f"Votre paiement pour {trajet} est sécurisé.",
        paiement=paiement,
    )
    notifier(
        paiement.mission.transporteur,
        Notification.Type.PAIEMENT_ENCAISSE,
        f"Le paiement du client pour {trajet} a été sécurisé par AfriFlotte.",
        paiement=paiement,
    )

    return paiement


@transaction.atomic
def encaisser_paiement_manuel_service(paiement, agent, reference="", preuve_fichier=None, commentaire=""):
    """Un agent AfriFlotte (User.type_compte == 'AGENT') déclare avoir
    physiquement encaissé l'argent du client. Reste en ENCAISSE — pas encore
    SECURISE — jusqu'à validation admin : c'est le contrôle qui protège d'une
    erreur ou d'une fraude d'agent."""
    if agent.type_compte != 'AGENT':
        raise PermissionError("Seul un agent AfriFlotte peut encaisser un paiement manuel.")
    if paiement.mode != Paiement.Mode.MANUEL:
        raise ValueError("Ce paiement n'est pas en mode manuel.")
    if paiement.statut != Paiement.Statut.EN_ATTENTE:
        raise ValueError("Ce paiement a déjà été encaissé.")

    paiement.statut = Paiement.Statut.ENCAISSE
    paiement.agent = agent
    paiement.reference_externe = reference
    paiement.date_encaissement = timezone.now()
    paiement.save(update_fields=[
        "statut", "agent", "reference_externe", "date_encaissement", "updated_at"
    ])

    if preuve_fichier is not None:
        PreuvePaiement.objects.create(
            paiement=paiement,
            fichier=preuve_fichier,
            type_preuve=PreuvePaiement.TypePreuve.RECU_ESPECES,
            ajoute_par=agent,
            commentaire=commentaire,
        )

    trajet = f"{paiement.mission.demande.ville_depart} → {paiement.mission.demande.ville_arrivee}"

    notifier(
        paiement.mission.client,
        Notification.Type.PAIEMENT_ENCAISSE,
        f"Votre paiement en espèces pour {trajet} a été encaissé, en attente de validation.",
        paiement=paiement,
    )
    for admin in User.objects.filter(type_compte='ADMIN'):
        notifier(
            admin,
            Notification.Type.PAIEMENT_ENCAISSE,
            f"Paiement manuel à valider pour {trajet}.",
            paiement=paiement,
        )

    return paiement


@transaction.atomic
def valider_paiement_manuel_service(paiement, admin):
    """ENCAISSE -> SECURISE, réservé à un admin — voir la note dans
    encaisser_paiement_manuel_service sur pourquoi ce n'est pas automatique."""
    if admin.type_compte != 'ADMIN':
        raise PermissionError("Seul un administrateur peut valider un paiement.")
    if paiement.mode != Paiement.Mode.MANUEL:
        raise ValueError("Ce paiement n'est pas en mode manuel.")
    if paiement.statut != Paiement.Statut.ENCAISSE:
        raise ValueError("Ce paiement n'est pas en attente de validation.")

    paiement.statut = Paiement.Statut.SECURISE
    paiement.date_securisation = timezone.now()
    paiement.save(update_fields=["statut", "date_securisation", "updated_at"])

    trajet = f"{paiement.mission.demande.ville_depart} → {paiement.mission.demande.ville_arrivee}"

    notifier(
        paiement.mission.client,
        Notification.Type.PAIEMENT_SECURISE,
        f"Votre paiement pour {trajet} a été validé et sécurisé.",
        paiement=paiement,
    )
    notifier(
        paiement.mission.transporteur,
        Notification.Type.PAIEMENT_SECURISE,
        f"Le paiement du client pour {trajet} est sécurisé.",
        paiement=paiement,
    )
    if paiement.agent_id:
        notifier(
            paiement.agent,
            Notification.Type.PAIEMENT_SECURISE,
            f"Votre encaissement pour {trajet} a été validé.",
            paiement=paiement,
        )

    return paiement


@transaction.atomic
def liberer_paiement_service(mission):
    """Appelé depuis `terminer_mission_service` : SECURISE -> LIBERE si un
    paiement sécurisé existe et qu'aucun litige n'est en cours. No-op
    silencieux sinon (pas de paiement, pas encore sécurisé, ou litige actif)
    — ne doit jamais faire échouer la clôture de la mission qui l'appelle.

    Requête fraîche plutôt que `mission.paiement` : `mission` peut être un
    objet obtenu avant que le paiement n'existe ou n'ait changé (ex. avant
    la confirmation webhook, arrivée de façon asynchrone) — le cache de
    relation Django sur cette instance en particulier serait alors périmé."""
    paiement = Paiement.objects.select_related(
        'mission__client', 'mission__transporteur', 'mission__demande'
    ).filter(mission_id=mission.id).first()
    if paiement is None:
        return None

    if paiement.statut != Paiement.Statut.SECURISE or paiement.litige_en_cours:
        return paiement

    paiement.statut = Paiement.Statut.LIBERE
    paiement.date_liberation = timezone.now()
    paiement.save(update_fields=["statut", "date_liberation", "updated_at"])

    trajet = f"{paiement.mission.demande.ville_depart} → {paiement.mission.demande.ville_arrivee}"

    notifier(
        paiement.mission.transporteur,
        Notification.Type.PAIEMENT_LIBERE,
        f"Les fonds de la mission {trajet} sont libérés, versement à venir.",
        paiement=paiement,
    )
    for admin in User.objects.filter(type_compte='ADMIN'):
        notifier(
            admin,
            Notification.Type.PAIEMENT_LIBERE,
            f"Paiement à verser au transporteur pour {trajet}.",
            paiement=paiement,
        )

    return paiement


@transaction.atomic
def marquer_verse_service(paiement, admin, reference="", preuve_fichier=None, commentaire=""):
    """LIBERE -> VERSE : enregistre que l'admin a effectué le virement réel
    (Mobile Money/banque) hors app. Pas d'appel API de payout — décision
    actée avec l'utilisateur (versement manuel pour cette version)."""
    if admin.type_compte != 'ADMIN':
        raise PermissionError("Seul un administrateur peut enregistrer un versement.")
    if paiement.statut != Paiement.Statut.LIBERE:
        raise ValueError("Ce paiement n'est pas prêt à être versé.")

    paiement.statut = Paiement.Statut.VERSE
    paiement.date_versement = timezone.now()
    if reference:
        paiement.reference_externe = reference
    paiement.save(update_fields=["statut", "date_versement", "reference_externe", "updated_at"])

    if preuve_fichier is not None:
        PreuvePaiement.objects.create(
            paiement=paiement,
            fichier=preuve_fichier,
            type_preuve=PreuvePaiement.TypePreuve.JUSTIFICATIF_VIREMENT,
            ajoute_par=admin,
            commentaire=commentaire,
        )

    trajet = f"{paiement.mission.demande.ville_depart} → {paiement.mission.demande.ville_arrivee}"

    notifier(
        paiement.mission.transporteur,
        Notification.Type.PAIEMENT_VERSE,
        f"Le paiement de {paiement.montant_transporteur} {paiement.devise} pour {trajet} vous a été versé.",
        paiement=paiement,
    )

    return paiement


@transaction.atomic
def rembourser_paiement_service(mission, initiateur, motif, preuve_fichier=None):
    """Appelé depuis l'annulation d'une mission (vue `refuser_mission`) et
    depuis la résolution d'un litige en faveur du client. No-op silencieux si
    la mission n'a pas de paiement, ou si ce paiement est déjà VERSE/REMBOURSE
    — un paiement déjà versé au transporteur ne se rembourse pas tout seul
    ici, ça relèverait d'un litige, pas d'une annulation.

    Requête fraîche plutôt que `mission.paiement`, même raison que dans
    `liberer_paiement_service` : éviter un cache de relation périmé sur
    l'instance `mission` reçue."""
    paiement = Paiement.objects.select_related(
        'mission__client', 'mission__transporteur', 'mission__demande'
    ).filter(mission_id=mission.id).first()
    if paiement is None:
        return None

    if paiement.statut not in (Paiement.Statut.ENCAISSE, Paiement.Statut.SECURISE):
        return paiement

    if paiement.mode == Paiement.Mode.CARTE and paiement.reference_externe:
        rembourse_automatiquement = get_gateway().rembourser_transaction(
            paiement.reference_externe, paiement.montant_total
        )
        # Certains PSP (PayDunya notamment) n'ont aucune API de remboursement
        # liée à la transaction d'origine : le statut passe quand même à
        # REMBOURSE (le flux métier — annulation/litige — doit se conclure),
        # mais le motif est préfixé pour que l'admin sache qu'aucun argent
        # n'a réellement bougé automatiquement et qu'un geste manuel (virement,
        # mobile money...) reste nécessaire, comme pour le versement transporteur.
        if not rembourse_automatiquement:
            motif = f"[Remboursement manuel requis — PSP sans API de remboursement] {motif}"

    paiement.statut = Paiement.Statut.REMBOURSE
    paiement.motif_remboursement = motif
    paiement.date_remboursement = timezone.now()
    paiement.save(update_fields=["statut", "motif_remboursement", "date_remboursement", "updated_at"])

    if preuve_fichier is not None:
        PreuvePaiement.objects.create(
            paiement=paiement,
            fichier=preuve_fichier,
            type_preuve=PreuvePaiement.TypePreuve.JUSTIFICATIF_REMBOURSEMENT,
            ajoute_par=initiateur,
            commentaire=motif,
        )

    trajet = f"{paiement.mission.demande.ville_depart} → {paiement.mission.demande.ville_arrivee}"

    notifier(
        paiement.mission.client,
        Notification.Type.PAIEMENT_REMBOURSE,
        f"Votre paiement pour {trajet} a été remboursé : {motif}",
        paiement=paiement,
    )
    notifier(
        paiement.mission.transporteur,
        Notification.Type.PAIEMENT_REMBOURSE,
        f"Le paiement du client pour {trajet} a été remboursé (mission annulée).",
        paiement=paiement,
    )

    return paiement


@transaction.atomic
def ouvrir_litige_service(paiement, ouvert_par, motif):
    """Le client ou le transporteur de la mission peut ouvrir un litige sur
    un paiement déjà encaissé, tant qu'il n'est pas clos (VERSE/REMBOURSE/
    ECHEC/EN_ATTENTE — rien à contester sur un paiement pas encore fait)."""
    if ouvert_par.id not in (paiement.mission.client_id, paiement.mission.transporteur_id):
        raise PermissionError(
            "Seuls le client ou le transporteur de cette mission peuvent ouvrir un litige."
        )

    statuts_contestables = (Paiement.Statut.ENCAISSE, Paiement.Statut.SECURISE, Paiement.Statut.LIBERE)
    if paiement.statut not in statuts_contestables:
        raise ValueError("Aucun litige possible sur ce paiement dans son état actuel.")

    litige = Litige.objects.create(
        paiement=paiement,
        ouvert_par=ouvert_par,
        motif=motif,
    )

    paiement.litige_en_cours = True
    paiement.save(update_fields=["litige_en_cours", "updated_at"])

    trajet = f"{paiement.mission.demande.ville_depart} → {paiement.mission.demande.ville_arrivee}"
    autre_partie = (
        paiement.mission.transporteur
        if ouvert_par.id == paiement.mission.client_id
        else paiement.mission.client
    )

    notifier(
        autre_partie,
        Notification.Type.LITIGE_OUVERT,
        f"Un litige a été ouvert sur le paiement de {trajet}.",
        paiement=paiement,
    )
    for admin in User.objects.filter(type_compte='ADMIN'):
        notifier(
            admin,
            Notification.Type.LITIGE_OUVERT,
            f"Litige à examiner pour {trajet}.",
            paiement=paiement,
        )

    return litige


@transaction.atomic
def resoudre_litige_service(litige, admin, resolution, commentaire=""):
    """`resolution` : Litige.Statut.RESOLU_CLIENT (déclenche un remboursement),
    RESOLU_TRANSPORTEUR ou REJETE (lèvent juste le blocage — si la mission
    est déjà TERMINEE et le paiement toujours SECURISE, ça signifie que
    `liberer_paiement_service` a vu le litige actif et a dû s'abstenir : on
    rejoue la libération maintenant que le blocage est levé)."""
    if admin.type_compte != 'ADMIN':
        raise PermissionError("Seul un administrateur peut résoudre un litige.")
    if litige.statut not in (Litige.Statut.OUVERT, Litige.Statut.EN_EXAMEN):
        raise ValueError("Ce litige est déjà résolu.")

    resolutions_valides = (
        Litige.Statut.RESOLU_CLIENT, Litige.Statut.RESOLU_TRANSPORTEUR, Litige.Statut.REJETE
    )
    if resolution not in resolutions_valides:
        raise ValueError("Résolution invalide.")

    litige.statut = resolution
    litige.resolution_commentaire = commentaire
    litige.resolu_par = admin
    litige.resolu_at = timezone.now()
    litige.save()

    paiement = litige.paiement
    paiement.litige_en_cours = Litige.objects.filter(
        paiement=paiement,
        statut__in=[Litige.Statut.OUVERT, Litige.Statut.EN_EXAMEN],
    ).exclude(id=litige.id).exists()
    paiement.save(update_fields=["litige_en_cours", "updated_at"])

    trajet = f"{paiement.mission.demande.ville_depart} → {paiement.mission.demande.ville_arrivee}"

    notifier(
        paiement.mission.client,
        Notification.Type.LITIGE_RESOLU,
        f"Le litige sur le paiement de {trajet} a été résolu.",
        paiement=paiement,
    )
    notifier(
        paiement.mission.transporteur,
        Notification.Type.LITIGE_RESOLU,
        f"Le litige sur le paiement de {trajet} a été résolu.",
        paiement=paiement,
    )

    if paiement.litige_en_cours:
        return litige

    if resolution == Litige.Statut.RESOLU_CLIENT:
        rembourser_paiement_service(
            paiement.mission, admin, f"Litige résolu en faveur du client : {commentaire}"
        )
    elif paiement.statut == Paiement.Statut.SECURISE:
        # Requête fraîche plutôt que `paiement.mission.statut` : `paiement.mission`
        # peut être un objet mis en cache avant la terminaison de la mission
        # (le cache de relation de `paiement` a pu être repeuplé par une
        # requête antérieure à `terminer_mission_service`), donc potentiellement
        # périmé — voir la même note dans liberer_paiement_service.
        mission_terminee = Mission.objects.filter(
            id=paiement.mission_id, statut=Mission.Statut.TERMINEE
        ).exists()
        if mission_terminee:
            liberer_paiement_service(paiement.mission)

    return litige