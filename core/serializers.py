from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import authenticate
from django.utils import timezone
from .models import *
from .constants import (
    CAPACITE_PAR_FORMAT_CITERNE,
    ESSIEUX_PAR_FORMAT_BENNE,
    devise_pour_pays,
    formats_valides_pour_type,
    unite_capacite_pour_type,
)
from .telephone import (
    TelephoneInvalide,
    candidats_suffixe_telephone,
    correspond_localement,
    valider_et_normaliser,
)


def _url_absolue(fichier, request):
    """URL absolue d'un FileField/ImageField, ou `None` si le champ est vide.
    Un serializer imbriqué reçoit son contexte (donc `request`) du serializer
    racine via DRF — mais si jamais celui-ci manque (instanciation hors
    d'une vue), on retombe sur l'URL relative plutôt que de planter."""
    if not fichier:
        return None
    url = fichier.url
    return request.build_absolute_uri(url) if request else url


def _image_principale_camion(camion, request):
    """Même résolution `principale` sinon première image que côté Flutter
    (`Camion.imagePrincipaleUrl`), pour les serializers qui n'exposent pas
    la liste complète `images` mais juste une vignette (résumé camion dans
    proposition/mission/chauffeur)."""
    image = camion.images.filter(principale=True).first() or camion.images.first()
    return _url_absolue(image.image, request) if image else None


def valider_format_camion(type_camion, format_camion, format_autre):
    """Règles partagées entre `CamionSerializer` et `DemandeTransportSerializer`
    pour le couple `format_camion`/`format_autre` : lève une
    `serializers.ValidationError` si incohérent, sinon ne renvoie rien.

    - `format_camion` vide : toujours valide (le format reste optionnel).
    - Sinon, doit être dans `formats_valides_pour_type(type_camion)` — un
      "40 pieds" n'a pas de sens pour une benne, une classe de litrage n'a
      pas de sens pour un plateau.
    - `format_camion == 'AUTRE'` exige `format_autre` non vide : c'est la
      saisie libre qui donne son sens à "Autre".
    """
    if not format_camion:
        return

    if format_camion not in formats_valides_pour_type(type_camion):
        raise serializers.ValidationError({
            'format_camion': "Ce format ne correspond pas au type de camion choisi.",
        })

    if format_camion == 'AUTRE' and not format_autre:
        raise serializers.ValidationError({
            'format_autre': "Précisez le format (champ \"Autre\").",
        })


class TelephoneTokenObtainPairSerializer(TokenObtainPairSerializer):

    telephone = serializers.CharField(
        write_only=True
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # On enlève username affiché par défaut
        self.fields.pop("username", None)

    def validate(self, attrs):

        telephone = attrs.get("telephone")
        password = attrs.get("password")

        if not telephone or not password:
            raise serializers.ValidationError(
                {
                    "detail": "Téléphone et mot de passe sont requis."
                }
            )

        # Le champ ne contient pas l'indicatif (saisi en local uniquement à
        # la connexion) alors que `telephone` est stocké en E.164 : on
        # présélectionne par suffixe (index DB), puis on ne garde que les
        # candidats dont le numéro local (indicatif de LEUR pays retiré)
        # correspond exactement à la saisie — un suffixe E.164 peut mordre
        # sur l'indicatif d'un autre pays sans que le numéro local ne
        # corresponde réellement (cf. `correspond_localement`). Si malgré
        # tout deux comptes de pays différents ont le même numéro local
        # (cas rare), le mot de passe désambiguïse — le premier qui matche
        # gagne, exactement comme s'il n'y avait eu qu'un seul candidat.
        q = candidats_suffixe_telephone(telephone)
        preselection = User.objects.filter(q) if q is not None else User.objects.none()
        candidats = [
            candidat for candidat in preselection
            if correspond_localement(candidat.telephone, candidat.pays, telephone)
        ]

        user = None
        for candidat in candidats:
            if authenticate(username=candidat.username, password=password) is not None:
                user = candidat
                break

        if user is None:
            raise serializers.ValidationError(
                {
                    "detail": "Téléphone ou mot de passe incorrect."
                }
            )


        refresh = self.get_token(user)

        data = {
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        }


        from .contrats import CONTRAT_TRANSPORTEUR_VERSION

        data["user"] = {
            "id": user.id,
            "username": user.username,
            "telephone": user.telephone,
            "type_compte": user.type_compte,
            "nom_entreprise": user.nom_entreprise,
            "email": user.email,
            "adresse": user.adresse,
            "pays": user.pays,
            "contrat_transporteur_accepte": (
                user.contrat_transporteur_version_acceptee == CONTRAT_TRANSPORTEUR_VERSION
            ),
        }

        return data

class UserSerializer(serializers.ModelSerializer):

    password = serializers.CharField(
        write_only=True
    )

    # Optionnel : un compte sans email reste utilisable normalement, seule
    # la réinitialisation de mot de passe par email (core/views.py:
    # demander_reinitialisation, seul canal disponible, pas de passerelle
    # SMS) lui restera fermée. Décision produit — rendu obligatoire une
    # première fois, puis revenu optionnel pour ne pas bloquer l'inscription
    # tant que l'envoi d'email n'est pas configuré en production (cf.
    # EMAIL_HOST_PASSWORD dans settings.py).
    email = serializers.EmailField(required=False, allow_blank=True)

    # Écriture seule, jamais stocké tel quel : sert uniquement à valider
    # l'acceptation obligatoire du contrat transporteur ci-dessous, avant que
    # `create()` ne fige `contrat_transporteur_accepte_le`/`_version_acceptee`.
    accepte_contrat_transporteur = serializers.BooleanField(
        required=False,
        default=False,
        write_only=True,
    )

    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'password',
            'telephone',
            'email',
            'type_compte',
            'nom_entreprise',
            'adresse',
            'pays',
            'accepte_contrat_transporteur',
        ]

    # `/api/register/` (UserCreateView) est un endpoint public, sans
    # authentification — seul moyen de créer un compte ENTREPRISE/TRANSPORTEUR.
    # Sans cette restriction, n'importe qui pouvait s'auto-inscrire en
    # précisant "type_compte": "ADMIN" ou "AGENT" dans la requête et obtenir
    # un compte pleinement privilégié. Un compte ADMIN/AGENT ne se crée que
    # via /admin/ (CustomUserAdmin), par un administrateur déjà authentifié.
    TYPES_OUVERTS_A_LINSCRIPTION = ('TRANSPORTEUR', 'ENTREPRISE')

    def validate(self, attrs):
        type_compte = attrs.get('type_compte')
        if type_compte and type_compte not in self.TYPES_OUVERTS_A_LINSCRIPTION:
            raise serializers.ValidationError({
                'type_compte': ["Ce type de compte n'est pas disponible à l'inscription."]
            })

        # Le contrat transporteur (core/contrats.py) est une condition
        # préalable et obligatoire à l'inscription en tant que transporteur —
        # pas de compte TRANSPORTEUR sans acceptation explicite, jamais
        # supposée par défaut.
        if type_compte == 'TRANSPORTEUR' and not attrs.get('accepte_contrat_transporteur'):
            raise serializers.ValidationError({
                'accepte_contrat_transporteur': [
                    "Vous devez accepter le contrat de partenariat transporteur pour créer ce compte."
                ]
            })

        telephone = attrs.get('telephone')
        if telephone:
            pays = attrs.get('pays') or (self.instance.pays if self.instance else 'ML')
            try:
                telephone_normalise = valider_et_normaliser(pays, telephone)
            except TelephoneInvalide as exc:
                raise serializers.ValidationError({'telephone': [str(exc)]})

            attrs['telephone'] = telephone_normalise
            # `username` est dérivé du téléphone côté client (pas d'identifiant
            # de connexion séparé) : on le réaligne sur la forme normalisée pour
            # ne pas dépendre de ce que le client a effectivement envoyé.
            if attrs.get('username') == telephone:
                attrs['username'] = telephone_normalise

        return attrs

    def create(self, validated_data):

        type_compte = validated_data.get('type_compte')
        accepte_contrat = validated_data.pop('accepte_contrat_transporteur', False)

        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password'],
            telephone=validated_data.get('telephone'),
            email=validated_data.get('email'),
            type_compte=type_compte,
            nom_entreprise=validated_data.get('nom_entreprise'),
            adresse=validated_data.get('adresse'),
            # `.get(..., "ML")` plutôt que `.get(...)` : évite de passer
            # explicitement `None` à create_user (pays n'a pas `null=True`,
            # un None explicite écraserait le default="ML" du modèle et
            # ferait échouer le .save() sur la contrainte NOT NULL).
            pays=validated_data.get('pays', 'ML'),
        )

        if type_compte == 'TRANSPORTEUR' and accepte_contrat:
            from .contrats import CONTRAT_TRANSPORTEUR_VERSION
            user.contrat_transporteur_accepte_le = timezone.now()
            user.contrat_transporteur_version_acceptee = CONTRAT_TRANSPORTEUR_VERSION
            user.save(update_fields=[
                'contrat_transporteur_accepte_le',
                'contrat_transporteur_version_acceptee',
            ])

        return user

class ImageCamionSerializer(serializers.ModelSerializer):

    class Meta:
        model = ImageCamion
        fields = ['id', 'image', 'principale']
        # Seul `principale` est modifiable via ImageCamionDetailView (PATCH) :
        # remplacer la photo elle-même passe par une suppression + un nouvel
        # upload via ImageCamionCreateView, pas par une mise à jour ici.
        read_only_fields = ['id', 'image']

class CamionSerializer(serializers.ModelSerializer):

    images = ImageCamionSerializer(
        many=True,
        read_only=True
    )


    proprietaire = serializers.StringRelatedField(
        read_only=True
    )


    class Meta:

        model = Camion


        fields = [

            'id',

            'proprietaire',

            'type_camion',

            'format_camion',

            'format_autre',

            'essieux',

            'immatriculation',

            'marque',

            'modele',

            'annee',

            'capacite',

            'unite_capacite',

            'disponible',

            'ville',

            'pays',

            'latitude',

            'longitude',

            'images'

        ]


        read_only_fields = [

            'id',

            'proprietaire',

            'disponible',

            'images'

        ]

    def validate(self, data):
        # L'unité de capacité découle du type de camion (une benne ne se
        # mesure pas en litres) : on l'impose côté serveur plutôt que de
        # faire confiance à ce que le client envoie, pour que ce soit vrai
        # quel que soit l'appelant de l'API.
        type_camion = data.get(
            'type_camion',
            getattr(self.instance, 'type_camion', None),
        )
        if type_camion:
            data['unite_capacite'] = unite_capacite_pour_type(type_camion)

        format_camion = data.get(
            'format_camion',
            getattr(self.instance, 'format_camion', ''),
        )
        format_autre = data.get(
            'format_autre',
            getattr(self.instance, 'format_autre', ''),
        )
        valider_format_camion(type_camion, format_camion, format_autre)

        # Le format encode déjà `capacite` (une classe de litrage de
        # citerne) ou `essieux` (une configuration d'essieux de benne) :
        # sans ce recouvrement, rien n'empêchait d'enregistrer
        # "CITERNE_43000L" avec une capacité tapée à 20000, ou "BENNE_8X4"
        # avec 2 essieux. On impose la valeur dérivée du format plutôt que
        # de faire confiance à la saisie manuelle, qui peut diverger.
        if format_camion in CAPACITE_PAR_FORMAT_CITERNE:
            data['capacite'] = CAPACITE_PAR_FORMAT_CITERNE[format_camion]

        if format_camion in ESSIEUX_PAR_FORMAT_BENNE:
            data['essieux'] = ESSIEUX_PAR_FORMAT_BENNE[format_camion]

        return data


class CamionRechercheSerializer(CamionSerializer):
    """Utilisé uniquement par `RechercheCamionView` : ajoute la position
    résolue (camion / chauffeur affecté / valeur statique) et la distance au
    point de référence recherché. `RechercheCamionView.list()` calcule ces
    valeurs une fois par instance (pas de requête supplémentaire par camion)
    et les pose sur `_position_resolue`/`_distance_km` avant sérialisation."""

    position = serializers.SerializerMethodField()

    distance_km = serializers.SerializerMethodField()

    class Meta(CamionSerializer.Meta):
        fields = CamionSerializer.Meta.fields + ['position', 'distance_km']

    def get_position(self, obj):
        return getattr(obj, '_position_resolue', None)

    def get_distance_km(self, obj):
        distance = getattr(obj, '_distance_km', None)
        return round(distance, 1) if distance is not None else None


class ChauffeurResumeSerializer(serializers.ModelSerializer):
    """Version allégée du chauffeur, pour l'afficher à l'intérieur d'un
    camion (qui le conduit) — pendant de CamionResumeSerializer, dans
    l'autre sens."""

    photo = serializers.SerializerMethodField()

    def get_photo(self, obj):
        return _url_absolue(obj.photo, self.context.get('request'))

    class Meta:
        model = Chauffeur
        fields = ['id', 'nom', 'telephone', 'pays', 'photo']


class CamionFlotteSerializer(CamionRechercheSerializer):
    """Flotte du transporteur connecté, avec position résolue ET chauffeur
    actuellement affecté — utilisé par FlottePositionsView. Contrairement à
    CamionRechercheSerializer/RechercheCamionView (marché : uniquement les
    camions disponibles, sans identité du chauffeur, pour un client externe
    qui cherche un transporteur), celle-ci montre TOUS les camions du
    transporteur, y compris ceux en mission, avec qui les conduit."""

    chauffeur_actuel = serializers.SerializerMethodField()

    class Meta(CamionRechercheSerializer.Meta):
        fields = CamionRechercheSerializer.Meta.fields + ['chauffeur_actuel']

    def get_chauffeur_actuel(self, obj):
        chauffeur = obj.chauffeur_actuel
        return ChauffeurResumeSerializer(chauffeur).data if chauffeur else None


class ImageCamionCreateSerializer(serializers.ModelSerializer):

    class Meta:
        model = ImageCamion
        fields = ['id', 'camion', 'image', 'principale', 'date_ajout']
        read_only_fields = ['id', 'date_ajout']


class DemandeTransportSerializer(serializers.ModelSerializer):

    depart = serializers.CharField(source='ville_depart', read_only=True)
    destination = serializers.CharField(source='ville_arrivee', read_only=True)
    produit = serializers.CharField(source='description', read_only=True)

    # La marchandise doit être renseignée et décrite précisément : un client
    # ne doit pas pouvoir créer une demande sans dire ce qu'il veut
    # transporter (`description` du modèle reste blank=True/null=True pour
    # ne pas casser les anciennes demandes déjà en base, la contrainte est
    # donc imposée ici plutôt que sur le modèle).
    description = serializers.CharField(
        required=True,
        allow_blank=False,
        min_length=3,
        error_messages={
            'required': "La marchandise à transporter est obligatoire.",
            'blank': "La marchandise à transporter est obligatoire.",
            'min_length': "Précisez la marchandise (au moins 3 caractères).",
        },
    )

    # Devise dérivée du pays de départ — jamais stockée, pour ne pas créer une
    # deuxième source de vérité qui pourrait diverger de `pays_depart`.
    devise = serializers.SerializerMethodField()

    # Additif pour la vue admin plateforme (AdminDemandesView), qui liste les
    # demandes de tous les clients — sans ça, impossible de savoir à qui
    # appartient une demande sans recharger l'utilisateur à part.
    client_nom = serializers.SerializerMethodField()

    def get_devise(self, obj):
        return devise_pour_pays(obj.pays_depart)

    def get_client_nom(self, obj):
        return obj.client.nom_entreprise or obj.client.username

    def validate(self, attrs):
        # Même logique que CamionSerializer : seul un camion citerne
        # transporte du liquide, l'unité "litres" n'a de sens que pour lui.
        type_camion = attrs.get(
            'type_camion',
            getattr(self.instance, 'type_camion', None),
        )
        unite = attrs.get('unite', getattr(self.instance, 'unite', None))

        if type_camion == 'CITERNE' and unite != 'litres':
            raise serializers.ValidationError({
                'unite': "Une demande de camion citerne doit être exprimée en litres.",
            })

        if type_camion and type_camion != 'CITERNE' and unite == 'litres':
            raise serializers.ValidationError({
                'unite': "Seul un camion citerne peut être demandé en litres : utilisez tonnes ou kg.",
            })

        format_camion = attrs.get(
            'format_camion',
            getattr(self.instance, 'format_camion', ''),
        )
        format_autre = attrs.get(
            'format_autre',
            getattr(self.instance, 'format_autre', ''),
        )
        valider_format_camion(type_camion, format_camion, format_autre)

        # Une demande déjà répondue (plus OUVERTE) ne doit plus pouvoir être
        # modifiée : un transporteur a pu proposer sur la base des
        # informations d'origine, les changer après coup les rendrait
        # invalides sans qu'il en soit informé.
        if self.instance is not None and self.instance.statut != 'OUVERTE':
            raise serializers.ValidationError({
                'statut': "Cette demande n'est plus modifiable (elle n'est plus ouverte).",
            })

        return attrs

    class Meta:
        model = DemandeTransport
        fields = [
            'id',
            'client',
            'type_camion',
            'format_camion',
            'format_autre',
            'nombre_camions',
            'ville_depart',
            'ville_arrivee',
            'description',
            'quantite',
            'pays_depart',
            'pays_arrivee',
            'latitude_depart',
            'longitude_depart',
            'latitude_arrivee',
            'longitude_arrivee',
            'unite',
            'date_chargement',
            'prix_propose',
            'statut',
            'date_creation',
            'depart',
            'destination',
            'produit',
            'devise',
            'client_nom',
        ]

        # Le client est déduit de l'utilisateur authentifié, jamais du body.
        read_only_fields = [
            'client',
            'date_creation',
        ]


class CamionResumeSerializer(serializers.ModelSerializer):
    """Version allégée du camion, pour l'afficher à l'intérieur d'un chauffeur
    ou d'une affectation sans embarquer tout le détail du véhicule."""

    image_principale = serializers.SerializerMethodField()

    def get_image_principale(self, obj):
        return _image_principale_camion(obj, self.context.get('request'))

    class Meta:
        model = Camion
        fields = [
            'id',
            'immatriculation',
            'type_camion',
            'marque',
            'modele',
            'image_principale',
        ]


class ChauffeurSerializer(serializers.ModelSerializer):

    # Affectation courante, dérivée de l'historique — jamais envoyée par le client.
    camion_actuel = CamionResumeSerializer(
        read_only=True
    )

    camion_actuel_id = serializers.SerializerMethodField()

    # Additif pour la vue admin plateforme (AdminChauffeursView), qui liste
    # les chauffeurs de tous les transporteurs — même formule que
    # `CamionSerializer.proprietaire`/`MissionSerializer.get_transporteur_nom`.
    transporteur_nom = serializers.SerializerMethodField()

    def get_camion_actuel_id(self, obj):
        camion = obj.camion_actuel
        return camion.id if camion else None

    def get_transporteur_nom(self, obj):
        return obj.transporteur.nom_entreprise or obj.transporteur.username

    class Meta:
        model = Chauffeur
        fields = [
            'id',
            'nom',
            'telephone',
            'numero_permis',
            'date_expiration_permis',
            'code_acces',
            'photo',
            'pays',
            'disponible',
            'actif',
            'latitude',
            'longitude',
            'position_updated_at',
            'created_at',
            'camion_actuel',
            'camion_actuel_id',
            'transporteur_nom',
        ]
        read_only_fields = ['created_at', 'latitude', 'longitude', 'position_updated_at']

    def validate(self, attrs):
        """`telephone` est unique globalement et sert d'identifiant de connexion
        au chauffeur : on normalise selon le plan de numérotation de `pays`
        avant de vérifier l'unicité (un `validate_telephone` field-level
        n'aurait pas d'accès simple à `pays`)."""
        telephone = attrs.get('telephone')
        if telephone:
            pays = attrs.get('pays') or (self.instance.pays if self.instance else 'ML')
            try:
                telephone = valider_et_normaliser(pays, telephone)
            except TelephoneInvalide as exc:
                raise serializers.ValidationError({'telephone': [str(exc)]})

            qs = Chauffeur.objects.filter(telephone=telephone)
            if self.instance is not None:
                qs = qs.exclude(pk=self.instance.pk)

            if qs.exists():
                raise serializers.ValidationError({
                    'telephone': ["Un chauffeur est déjà enregistré avec ce numéro de téléphone."],
                })

            attrs['telephone'] = telephone

        return attrs


class ChauffeurPhotoSerializer(serializers.ModelSerializer):
    """Volontairement limité au seul champ `photo` : utilisé par la vue
    ouverte `chauffeur_modifier_photo` (identifiée par `chauffeur_id` dans
    l'URL, sans JWT — les comptes chauffeur n'ont pas de token aujourd'hui),
    ce `Meta.fields` restreint est ce qui empêche cette route de servir à
    modifier autre chose (code_acces, actif...) que la photo."""

    class Meta:
        model = Chauffeur
        fields = ['photo']


class AffectationChauffeurSerializer(serializers.ModelSerializer):

    chauffeur_nom = serializers.CharField(
        source="chauffeur.nom",
        read_only=True
    )

    camion_immatriculation = serializers.CharField(
        source="camion.immatriculation",
        read_only=True
    )

    active = serializers.BooleanField(
        read_only=True
    )

    class Meta:
        model = AffectationChauffeur
        fields = [
            'id',
            'chauffeur',
            'chauffeur_nom',
            'camion',
            'camion_immatriculation',
            'date_debut',
            'date_fin',
            'commentaire',
            'active',
        ]
        read_only_fields = ['date_fin']

    def validate(self, attrs):
        """Le camion et le chauffeur doivent appartenir au même transporteur —
        celui qui fait la requête."""
        request = self.context.get("request")
        chauffeur = attrs.get("chauffeur")
        camion = attrs.get("camion")

        if request is not None and request.user.is_authenticated:
            if chauffeur is not None and chauffeur.transporteur_id != request.user.id:
                raise serializers.ValidationError({
                    "chauffeur": "Ce chauffeur ne fait pas partie de votre flotte."
                })

            if camion is not None and camion.proprietaire_id != request.user.id:
                raise serializers.ValidationError({
                    "camion": "Ce camion ne vous appartient pas."
                })

        return attrs


class PropositionCamionSerializer(serializers.ModelSerializer):

    camion_immatriculation = serializers.CharField(
        source="camion.immatriculation",
        read_only=True
    )

    # `chauffeur` est optionnel sur PropositionCamion : un SerializerMethodField
    # évite l'AttributeError qu'un `source="chauffeur.nom"` lèverait quand il
    # est None (contrairement à AffectationChauffeur, où chauffeur est requis).
    chauffeur_nom = serializers.SerializerMethodField()

    # Photos du camion/chauffeur proposé, absentes jusqu'ici : l'entreprise
    # ne recevait que des id bruts et ne pouvait jamais voir à quoi
    # ressemblait le camion/chauffeur qu'on lui proposait. `camion_images`
    # renvoie la galerie complète (pas juste la principale) pour permettre
    # au client de l'ouvrir en grand côté app, comme `CamionSerializer.images`.
    camion_images = ImageCamionSerializer(
        source='camion.images',
        many=True,
        read_only=True
    )
    chauffeur_photo = serializers.SerializerMethodField()

    class Meta:
        model = PropositionCamion
        fields = [
            'camion',
            'camion_immatriculation',
            'camion_images',
            'chauffeur',
            'chauffeur_nom',
            'chauffeur_photo',
            'ordre'
        ]

    def get_chauffeur_nom(self, obj):
        return obj.chauffeur.nom if obj.chauffeur else None

    def get_chauffeur_photo(self, obj):
        return _url_absolue(obj.chauffeur.photo, self.context.get('request')) if obj.chauffeur else None

    def validate(self, attrs):
        """Le camion (et le chauffeur, s'il est précisé) doivent appartenir
        au transporteur qui envoie la proposition — même contrôle que
        AffectationChauffeurSerializer.validate."""
        request = self.context.get("request")
        camion = attrs.get("camion")
        chauffeur = attrs.get("chauffeur")

        if request is not None and request.user.is_authenticated:
            if camion is not None and camion.proprietaire_id != request.user.id:
                raise serializers.ValidationError({
                    "camion": "Ce camion ne vous appartient pas."
                })

            if chauffeur is not None and chauffeur.transporteur_id != request.user.id:
                raise serializers.ValidationError({
                    "chauffeur": "Ce chauffeur ne fait pas partie de votre flotte."
                })

        return attrs


class PropositionSerializer(serializers.ModelSerializer):

    camions = PropositionCamionSerializer(
        many=True
    )

    # Évitent à Flutter de recharger la demande pour afficher une proposition.
    depart = serializers.CharField(
        source='demande.ville_depart',
        read_only=True
    )

    destination = serializers.CharField(
        source='demande.ville_arrivee',
        read_only=True
    )

    type_camion = serializers.CharField(
        source='demande.type_camion',
        read_only=True
    )

    pays_depart = serializers.CharField(
        source='demande.pays_depart',
        read_only=True
    )

    pays_arrivee = serializers.CharField(
        source='demande.pays_arrivee',
        read_only=True
    )

    transporteur_nom = serializers.SerializerMethodField()

    devise = serializers.SerializerMethodField()

    class Meta:
        model = Proposition
        fields = [
            'id',
            'demande',
            'depart',
            'destination',
            'type_camion',
            'pays_depart',
            'pays_arrivee',
            'transporteur',
            'transporteur_nom',
            'prix',
            'devise',
            'message',
            'delai_depart',
            'valide_jusquau',
            'statut',
            'camions',
            'created_at'
        ]

        # Le transporteur est déduit de l'utilisateur authentifié dans la vue,
        # jamais du body — même règle que CamionSerializer.proprietaire.
        read_only_fields = ['transporteur', 'statut']

    def get_transporteur_nom(self, obj):
        transporteur = obj.transporteur
        if transporteur is None:
            return None
        return transporteur.nom_entreprise or transporteur.username

    def get_devise(self, obj):
        return devise_pour_pays(obj.demande.pays_depart)

    def validate(self, attrs):
        """Chaque camion proposé doit être du type de camion demandé — la
        demande d'une entreprise pour une CITERNE ne doit pas pouvoir
        recevoir une proposition avec une BENNE. `PropositionCamionSerializer.
        validate` contrôle déjà la propriété du camion/chauffeur mais n'a
        pas accès à la demande (serializer imbriqué) ; ce contrôle-ci se
        fait donc au niveau du serializer parent, qui a les deux.

        Une seule proposition (d'un seul transporteur) doit couvrir la
        totalité des camions demandés : accepter une proposition refuse
        automatiquement toutes les autres sur la même demande
        (`accepter_proposition_service`), donc une proposition partielle
        laisserait la demande satisfaite alors qu'il manque des camions."""
        demande = attrs.get('demande')
        camions = attrs.get('camions') or []

        if demande is not None:
            for camion_data in camions:
                camion = camion_data.get('camion')
                if camion is not None and camion.type_camion != demande.type_camion:
                    raise serializers.ValidationError({
                        'camions': (
                            f"Le camion {camion.immatriculation} est de type "
                            f"{camion.type_camion}, mais cette demande requiert "
                            f"un camion de type {demande.type_camion}."
                        )
                    })

            if len(camions) != demande.nombre_camions:
                raise serializers.ValidationError({
                    'camions': (
                        f"Cette demande requiert {demande.nombre_camions} camion(s), "
                        f"mais {len(camions)} ont été proposés. Votre proposition doit "
                        f"couvrir la totalité des camions demandés."
                    )
                })

        return attrs

    def create(self, validated_data):

        camions_data = validated_data.pop(
            'camions'
        )


        proposition = Proposition.objects.create(
            **validated_data
        )


        for camion_data in camions_data:

            PropositionCamion.objects.create(
                proposition=proposition,
                **camion_data
            )


        return proposition
    



class MissionCamionSerializer(serializers.ModelSerializer):

    statut_libelle = serializers.CharField(
        source='get_statut_display',
        read_only=True
    )

    camion_immatriculation = serializers.CharField(
        source='camion.immatriculation',
        read_only=True
    )

    # Mêmes ajouts que PropositionCamionSerializer : le client/l'entreprise
    # ne voyait ni le nom ni la photo du chauffeur, ni les photos du camion,
    # sur la mission qui lui est pourtant assignée. `camion_images` : galerie
    # complète, pas juste la principale (cf. commentaire équivalent plus haut).
    chauffeur_nom = serializers.SerializerMethodField()
    camion_images = ImageCamionSerializer(
        source='camion.images',
        many=True,
        read_only=True
    )
    chauffeur_photo = serializers.SerializerMethodField()

    class Meta:
        model = MissionCamion
        fields = [
            'id',
            'camion',
            'chauffeur',
            'chauffeur_nom',
            'statut',
            'statut_libelle',
            'camion_immatriculation',
            'camion_images',
            'chauffeur_photo',
        ]

    def get_chauffeur_nom(self, obj):
        return obj.chauffeur.nom if obj.chauffeur else None

    def get_chauffeur_photo(self, obj):
        return _url_absolue(obj.chauffeur.photo, self.context.get('request')) if obj.chauffeur else None



class MissionSerializer(serializers.ModelSerializer):

    camions = MissionCamionSerializer(
        many=True,
        read_only=True
    )


    # Champs d'affichage : évitent au mobile de recharger la demande
    # et le transporteur pour pouvoir rendre une carte de mission.
    depart = serializers.CharField(
        source='demande.ville_depart',
        read_only=True
    )

    destination = serializers.CharField(
        source='demande.ville_arrivee',
        read_only=True
    )

    produit = serializers.CharField(
        source='demande.description',
        read_only=True
    )

    type_camion = serializers.CharField(
        source='demande.type_camion',
        read_only=True
    )

    pays_depart = serializers.CharField(
        source='demande.pays_depart',
        read_only=True
    )

    pays_arrivee = serializers.CharField(
        source='demande.pays_arrivee',
        read_only=True
    )

    date_chargement = serializers.DateField(
        source='demande.date_chargement',
        read_only=True
    )

    statut_libelle = serializers.CharField(
        source='get_statut_display',
        read_only=True
    )

    transporteur_nom = serializers.SerializerMethodField()

    # Additif pour la vue admin plateforme (AdminMissionsView), qui liste les
    # missions de tous les clients — `transporteur_nom` existait déjà pour
    # l'écran transporteur/client, mais aucun des deux n'avait besoin de
    # savoir à quel client appartient une mission qui n'est pas la sienne.
    client_nom = serializers.SerializerMethodField()

    nombre_camions = serializers.SerializerMethodField()

    devise = serializers.SerializerMethodField()


    class Meta:
        model = Mission

        fields = [
            'id',
            'demande',
            'proposition',
            'client',
            'transporteur',
            'prix_final',
            'devise',
            'statut',
            'camions',
            'date_creation',
            'date_depart',
            'date_arrivee',
            'depart',
            'destination',
            'produit',
            'type_camion',
            'pays_depart',
            'pays_arrivee',
            'date_chargement',
            'statut_libelle',
            'transporteur_nom',
            'client_nom',
            'nombre_camions',
        ]


    def get_transporteur_nom(self, obj):

        transporteur = obj.transporteur

        if transporteur is None:
            return None

        return (
            transporteur.nom_entreprise
            or transporteur.username
        )

    def get_client_nom(self, obj):

        client = obj.client

        if client is None:
            return None

        return client.nom_entreprise or client.username

    def get_devise(self, obj):
        return devise_pour_pays(obj.demande.pays_depart)


    def get_nombre_camions(self, obj):

        return obj.camions.count()

class PositionGPSSerializer(serializers.ModelSerializer):

    class Meta:
        model = PositionGPS
        fields = [
            "id",
            "mission_camion",
            "latitude",
            "longitude",
            "vitesse",
            "precision",
            "batterie",
            "date",
            "source",
            "telephone_chauffeur",
        ]
        read_only_fields = [
            "date"
        ]




class ChauffeurLoginSerializer(serializers.Serializer):

    telephone = serializers.CharField()

    code_acces = serializers.CharField()


class ChauffeurPositionSerializer(serializers.ModelSerializer):
    """Ping de position envoyé par le téléphone du chauffeur, indépendant
    de toute mission en cours."""

    latitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=True
    )

    longitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=True
    )

    class Meta:
        model = Chauffeur
        fields = [
            "latitude",
            "longitude",
            "position_updated_at",
        ]
        read_only_fields = [
            "position_updated_at"
        ]




class ChauffeurMissionSerializer(serializers.ModelSerializer):
    """`id` reste l'id de la ligne `MissionCamion` (utilisé nulle part côté
    action) — `mission_id` est ajouté séparément car c'est lui qu'il faut
    passer à `chauffeur_demarrer_mission`/`chauffeur_terminer_mission`
    (ces vues opèrent sur `Mission`, pas `MissionCamion`)."""

    camion = serializers.CharField(
        source="camion.immatriculation"
    )

    trajet = serializers.SerializerMethodField()

    mission_id = serializers.IntegerField(
        source="mission.id",
        read_only=True
    )

    mission_statut = serializers.CharField(
        source="mission.statut",
        read_only=True
    )

    ville_depart = serializers.CharField(
        source="mission.demande.ville_depart",
        read_only=True
    )

    ville_arrivee = serializers.CharField(
        source="mission.demande.ville_arrivee",
        read_only=True
    )

    description = serializers.CharField(
        source="mission.demande.description",
        read_only=True
    )

    quantite = serializers.DecimalField(
        source="mission.demande.quantite",
        max_digits=10,
        decimal_places=2,
        read_only=True
    )

    date_depart = serializers.DateTimeField(
        source="mission.date_depart",
        read_only=True
    )

    date_arrivee = serializers.DateTimeField(
        source="mission.date_arrivee",
        read_only=True
    )

    prix_final = serializers.DecimalField(
        source="mission.prix_final",
        max_digits=12,
        decimal_places=2,
        read_only=True
    )

    devise = serializers.SerializerMethodField()

    observations = serializers.CharField(
        source="mission.observations",
        read_only=True
    )

    client_nom = serializers.SerializerMethodField()

    client_telephone = serializers.CharField(
        source="mission.client.telephone",
        read_only=True
    )

    # Nécessaire côté Flutter pour afficher client_telephone en format local
    # (formaterLocal a besoin du pays pour savoir quel indicatif retirer).
    client_pays = serializers.CharField(
        source="mission.client.pays",
        read_only=True
    )

    class Meta:
        model = MissionCamion
        fields = [
            "id",
            "mission_id",
            "mission_statut",
            "camion",
            "trajet",
            "ville_depart",
            "ville_arrivee",
            "description",
            "quantite",
            "date_depart",
            "date_arrivee",
            "prix_final",
            "devise",
            "observations",
            "client_nom",
            "client_telephone",
            "client_pays",
            "statut",
        ]


    def get_trajet(self, obj):

        return (
            f"{obj.mission.demande.ville_depart} → "
            f"{obj.mission.demande.ville_arrivee}"
        )

    def get_devise(self, obj):
        return devise_pour_pays(obj.mission.demande.pays_depart)

    def get_client_nom(self, obj):
        return obj.mission.client.nom_entreprise or obj.mission.client.username


class RevenuDeviseSerializer(serializers.Serializer):
    """Un total de revenus pour une devise donnée (cf. `revenus_par_devise`
    dans services.py). La devise n'est jamais stockée sur Mission : elle est
    dérivée de `demande.pays_depart` par mission puis regroupée en Python,
    d'où cette ventilation en liste plutôt qu'un total unique — un même
    transporteur/la plateforme peut avoir des missions dans plusieurs pays
    CEDEAO donc plusieurs devises."""

    devise = serializers.CharField()

    montant = serializers.FloatField()


class TransporteurDashboardSerializer(serializers.Serializer):

    # ==========================
    # CAMIONS
    # ==========================

    camions_total = serializers.IntegerField(
        default=0
    )

    camions_disponibles = serializers.IntegerField(
        default=0
    )

    camions_en_mission = serializers.IntegerField(
        default=0
    )

    camions_maintenance = serializers.IntegerField(
        default=0
    )

    camions_hors_service = serializers.IntegerField(
        default=0
    )


    # ==========================
    # CHAUFFEURS
    # ==========================

    chauffeurs_total = serializers.IntegerField(
        default=0
    )

    chauffeurs_disponibles = serializers.IntegerField(
        default=0
    )

    chauffeurs_en_mission = serializers.IntegerField(
        default=0
    )


    # ==========================
    # MISSIONS
    # ==========================

    missions_planifiees = serializers.IntegerField(
        default=0
    )

    missions_en_cours = serializers.IntegerField(
        default=0
    )

    missions_terminees = serializers.IntegerField(
        default=0
    )

    missions_annulees = serializers.IntegerField(
        default=0
    )

    missions_aujourdhui = serializers.IntegerField(
        default=0
    )


    # ==========================
    # DEMANDES / PROPOSITIONS
    # ==========================

    demandes_disponibles = serializers.IntegerField(
        default=0
    )

    propositions_en_attente = serializers.IntegerField(
        default=0
    )


    # ==========================
    # FINANCES
    # ==========================

    revenus = RevenuDeviseSerializer(
        many=True,
        default=list
    )

    revenus_mois = RevenuDeviseSerializer(
        many=True,
        default=list
    )

    revenus_annee = RevenuDeviseSerializer(
        many=True,
        default=list
    )


    # ==========================
    # NOTIFICATIONS
    # ==========================

    notifications_non_lues = serializers.IntegerField(
        default=0
    )


class AdminDashboardSerializer(serializers.Serializer):
    """Statistiques globales de la plateforme, tous transporteurs/entreprises
    confondus — réservé aux comptes ADMIN (cf. AdminDashboardView)."""

    # ==========================
    # COMPTES
    # ==========================

    transporteurs_total = serializers.IntegerField(default=0)

    entreprises_total = serializers.IntegerField(default=0)

    chauffeurs_total = serializers.IntegerField(default=0)


    # ==========================
    # CAMIONS
    # ==========================

    camions_total = serializers.IntegerField(default=0)

    camions_disponibles = serializers.IntegerField(default=0)


    # ==========================
    # MISSIONS
    # ==========================

    missions_total = serializers.IntegerField(default=0)

    missions_en_cours = serializers.IntegerField(default=0)

    missions_terminees = serializers.IntegerField(default=0)


    # ==========================
    # DEMANDES
    # ==========================

    demandes_ouvertes = serializers.IntegerField(default=0)


    # ==========================
    # FINANCES
    # ==========================

    revenus_total = RevenuDeviseSerializer(many=True, default=list)


class ClientDashboardSerializer(serializers.Serializer):
    """Statistiques du compte ENTREPRISE (client) connecté — pendant client de
    TransporteurDashboardSerializer, cf. ClientDashboardView."""

    # ==========================
    # DEMANDES
    # ==========================

    demandes_total = serializers.IntegerField(default=0)

    demandes_ouvertes = serializers.IntegerField(default=0)

    demandes_en_cours = serializers.IntegerField(default=0)

    demandes_terminees = serializers.IntegerField(default=0)

    demandes_annulees = serializers.IntegerField(default=0)


    # ==========================
    # MISSIONS
    # ==========================

    missions_total = serializers.IntegerField(default=0)

    missions_en_cours = serializers.IntegerField(default=0)

    missions_terminees = serializers.IntegerField(default=0)


    # ==========================
    # PROPOSITIONS
    # ==========================

    propositions_en_attente = serializers.IntegerField(default=0)


    # ==========================
    # DEPENSES
    # ==========================

    depenses_total = RevenuDeviseSerializer(many=True, default=list)

    depenses_mois = RevenuDeviseSerializer(many=True, default=list)


    # ==========================
    # NOTIFICATIONS
    # ==========================

    notifications_non_lues = serializers.IntegerField(default=0)


class PreuvePaiementSerializer(serializers.ModelSerializer):

    type_preuve_libelle = serializers.CharField(
        source="get_type_preuve_display",
        read_only=True
    )

    class Meta:
        model = PreuvePaiement
        fields = [
            'id',
            'fichier',
            'type_preuve',
            'type_preuve_libelle',
            'ajoute_par',
            'commentaire',
            'created_at',
        ]
        read_only_fields = ['ajoute_par', 'created_at']


class LitigeSerializer(serializers.ModelSerializer):

    statut_libelle = serializers.CharField(
        source="get_statut_display",
        read_only=True
    )
    ouvert_par_nom = serializers.SerializerMethodField()

    class Meta:
        model = Litige
        fields = [
            'id',
            'paiement',
            'ouvert_par',
            'ouvert_par_nom',
            'motif',
            'statut',
            'statut_libelle',
            'resolution_commentaire',
            'resolu_par',
            'created_at',
            'resolu_at',
        ]
        read_only_fields = [
            'paiement', 'ouvert_par', 'statut', 'resolution_commentaire',
            'resolu_par', 'created_at', 'resolu_at',
        ]

    def get_ouvert_par_nom(self, obj):
        if not obj.ouvert_par:
            return None
        return obj.ouvert_par.nom_entreprise or obj.ouvert_par.username


class PaiementSerializer(serializers.ModelSerializer):
    """`devise` n'est PAS dérivée ici via `devise_pour_pays` comme le reste du
    projet — elle est stockée en dur sur `Paiement` (cf. la note dans
    models.py) car c'est une ligne financière figée, pas un libellé
    d'affichage recalculé à la volée."""

    mode_libelle = serializers.CharField(source="get_mode_display", read_only=True)
    statut_libelle = serializers.CharField(source="get_statut_display", read_only=True)
    mission_trajet = serializers.SerializerMethodField()
    client_nom = serializers.SerializerMethodField()
    transporteur_nom = serializers.SerializerMethodField()
    preuves = PreuvePaiementSerializer(many=True, read_only=True)
    litiges = LitigeSerializer(many=True, read_only=True)

    class Meta:
        model = Paiement
        fields = [
            'id',
            'mission',
            'mission_trajet',
            'client_nom',
            'transporteur_nom',
            'mode',
            'mode_libelle',
            'montant_total',
            'devise',
            'commission_taux',
            'commission_montant',
            'montant_transporteur',
            'statut',
            'statut_libelle',
            'agent',
            'reference_externe',
            'carte_marque',
            'carte_dernier4',
            'carte_expiration',
            'mobile_operateur',
            'mobile_numero',
            'litige_en_cours',
            'motif_remboursement',
            'date_encaissement',
            'date_securisation',
            'date_liberation',
            'date_versement',
            'date_remboursement',
            'created_at',
            'preuves',
            'litiges',
        ]
        read_only_fields = [
            'montant_total', 'devise', 'commission_taux', 'commission_montant',
            'montant_transporteur', 'statut', 'agent', 'reference_externe',
            'carte_marque', 'carte_dernier4', 'carte_expiration',
            'litige_en_cours', 'motif_remboursement', 'created_at',
        ]

    def get_mission_trajet(self, obj):
        return f"{obj.mission.demande.ville_depart} → {obj.mission.demande.ville_arrivee}"

    def get_client_nom(self, obj):
        return obj.mission.client.nom_entreprise or obj.mission.client.username

    def get_transporteur_nom(self, obj):
        return obj.mission.transporteur.nom_entreprise or obj.mission.transporteur.username


class NotificationSerializer(serializers.ModelSerializer):

    type_notification_libelle = serializers.CharField(
        source="get_type_notification_display",
        read_only=True
    )

    # Sourcés en direct depuis la Proposition liée (pas depuis `message`, qui
    # est un texte figé au moment de la création) : si la proposition a
    # depuis été supprimée, `proposition` est `None` — `message` reste
    # affiché tel quel comme trace historique, mais l'app sait qu'il n'y a
    # plus rien à ouvrir/décider dessus.
    proposition_prix = serializers.SerializerMethodField()
    proposition_devise = serializers.SerializerMethodField()
    proposition_statut = serializers.SerializerMethodField()

    # Même principe pour le paiement lié (types PAIEMENT_*/LITIGE_*).
    paiement_montant = serializers.SerializerMethodField()
    paiement_devise = serializers.SerializerMethodField()
    paiement_statut = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = [
            'id',
            'type_notification',
            'type_notification_libelle',
            'message',
            'lue',
            'created_at',
            'proposition',
            'proposition_prix',
            'proposition_devise',
            'proposition_statut',
            'paiement',
            'paiement_montant',
            'paiement_devise',
            'paiement_statut',
        ]
        read_only_fields = [
            'type_notification', 'message', 'created_at', 'proposition', 'paiement',
        ]

    def get_proposition_prix(self, obj):
        return obj.proposition.prix if obj.proposition else None

    def get_proposition_devise(self, obj):
        if not obj.proposition:
            return None
        return devise_pour_pays(obj.proposition.demande.pays_depart)

    def get_proposition_statut(self, obj):
        return obj.proposition.statut if obj.proposition else None

    def get_paiement_montant(self, obj):
        return obj.paiement.montant_total if obj.paiement else None

    def get_paiement_devise(self, obj):
        return obj.paiement.devise if obj.paiement else None

    def get_paiement_statut(self, obj):
        return obj.paiement.statut if obj.paiement else None


class ProfilUpdateSerializer(serializers.ModelSerializer):
    """Mise à jour des informations personnelles depuis l'écran "Modifier mon
    profil" — volontairement restreint à des champs sans impact identitaire
    (ni `username`, ni `telephone`, qui servent de clé de connexion)."""

    class Meta:
        model = User
        fields = [
            'nom_entreprise',
            'email',
            'adresse',
            'pays',
            'photo_profil',
        ]


class ChangerMotDePasseSerializer(serializers.Serializer):

    ancien_mot_de_passe = serializers.CharField(
        write_only=True
    )

    nouveau_mot_de_passe = serializers.CharField(
        write_only=True,
        min_length=6,
    )


class DemandeReinitialisationSerializer(serializers.Serializer):

    email = serializers.EmailField()


class ConfirmerReinitialisationSerializer(serializers.Serializer):

    email = serializers.EmailField()

    code = serializers.CharField(
        min_length=6,
        max_length=6,
    )

    nouveau_mot_de_passe = serializers.CharField(
        write_only=True,
        min_length=6,
    )