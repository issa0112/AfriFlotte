from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone

from .constants import FORMAT_CAMION_CHOICES, PAYS_CEDEAO_CHOICES, TYPE_CAMION_CHOICES

# NB : pas de RegexValidator ici sur `telephone` — DRF copie automatiquement
# les validators d'un champ modèle sur le champ serializer correspondant, ce
# qui bloquerait au niveau champ (avant `validate()`) l'envoi d'un numéro
# local seul (sans indicatif), pourtant une forme volontairement acceptée en
# entrée. La validation par pays (longueur/préfixe) vit dans
# core/telephone.py et s'applique dans les serializers, seuls endroits où
# `pays` est connu.


class User(AbstractUser):

    TYPE = (
        ('TRANSPORTEUR', 'Transporteur'),
        ('ENTREPRISE', 'Entreprise'),
        ('ADMIN', 'Administrateur'),
        ('AGENT', 'Agent AfriFlotte'),
    )

    telephone = models.CharField(
        max_length=20,
        unique=True,
        null=True
    )

    type_compte = models.CharField(
        max_length=20,
        choices=TYPE,
        default='TRANSPORTEUR'
    )

    nom_entreprise = models.CharField(
        max_length=150,
        blank=True,
        null=True
    )

    adresse = models.CharField(
        max_length=255,
        blank=True,
        null=True
    )

    pays = models.CharField(
        max_length=2,
        choices=PAYS_CEDEAO_CHOICES,
        default="ML"
    )

    photo_profil = models.ImageField(
        upload_to="profils/",
        blank=True,
        null=True
    )

    code_reinitialisation = models.CharField(
        max_length=6,
        blank=True,
        null=True
    )

    code_reinitialisation_expiration = models.DateTimeField(
        blank=True,
        null=True
    )

    date_creation = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return self.username


class Camion(models.Model):

    TYPE_CAMION = TYPE_CAMION_CHOICES

    proprietaire = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="camions"
    )

    type_camion = models.CharField(
        max_length=50,
        choices=TYPE_CAMION
    )

    # Gabarit précis du camion (ex. "40 pieds" pour un porte-conteneur,
    # "20 000 L" pour une citerne) — voir FORMAT_CAMION_CHOICES/
    # FORMATS_PAR_TYPE dans constants.py. Vide pour un type sans format
    # standard (benne, porte-engin). `format_autre` porte la saisie libre
    # quand `format_camion == 'AUTRE'`.
    format_camion = models.CharField(
        max_length=30,
        choices=FORMAT_CAMION_CHOICES,
        blank=True,
        default=""
    )

    format_autre = models.CharField(
        max_length=100,
        blank=True,
        default=""
    )

    essieux = models.PositiveSmallIntegerField(
        null=True,
        blank=True,
        help_text="Nombre d'essieux du camion."
    )

    immatriculation = models.CharField(
        max_length=50,
        unique=True
    )

    marque = models.CharField(
        max_length=100,
        blank=True,
        null=True
    )

    modele = models.CharField(
        max_length=100,
        blank=True,
        null=True
    )

    annee = models.IntegerField(
        blank=True,
        null=True
    )

    capacite = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    unite_capacite = models.CharField(
        max_length=20,
        default="litres"
    )

    disponible = models.BooleanField(
        default=True
    )

    date_creation = models.DateTimeField(
        auto_now_add=True
    )

    ville = models.CharField(
        max_length=100,
        default="Bamako"
    )

    pays = models.CharField(
        max_length=2,
        choices=PAYS_CEDEAO_CHOICES,
        default="ML"
    )

    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True
    )

    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True
    )

    suivi_par_telephone = models.BooleanField(
        default=False
    )

    mode_suivi = models.CharField(
        max_length=20,
        choices=[('GPS', 'GPS'), ('TELEPHONE', 'Téléphone')],
        default='GPS'
    )

    position_updated_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Date de la dernière position réellement rapportée (distingue une valeur statique jamais rafraîchie d'une vraie remontée GPS)."
    )

    @property
    def affectation_active(self):
        """Affectation en cours (celle qui n'a pas de date de fin), sinon None."""
        return self.affectations.filter(
            date_fin__isnull=True
        ).select_related("chauffeur").first()

    @property
    def chauffeur_actuel(self):
        affectation = self.affectation_active
        return affectation.chauffeur if affectation else None

    def __str__(self):
        return self.immatriculation

class ImageCamion(models.Model):

    camion = models.ForeignKey(
        Camion,
        on_delete=models.CASCADE,
        related_name="images"
    )

    image = models.ImageField(
        upload_to="camions/"
    )

    principale = models.BooleanField(
        default=False
    )

    date_ajout = models.DateTimeField(
        auto_now_add=True
    )


    def save(self, *args, **kwargs):
        from django.core.exceptions import ValidationError

        # `self.pk is None` : uniquement à la création d'une nouvelle image.
        # Sans ce garde-fou, la limite de 4 bloquait aussi la mise à jour
        # d'une image déjà existante (ex. la définir comme principale) dès
        # qu'un camion avait atteint ses 4 photos — un camion déjà à 4/4
        # devenait alors incapable de changer sa photo principale.
        if self.pk is None and self.camion.images.count() >= 4:
            raise ValidationError(
                "Un camion ne peut pas avoir plus de 4 images."
            )

        super().save(*args, **kwargs)


    def __str__(self):
        return f"Image {self.camion.immatriculation}"
    
class Chauffeur(models.Model):

    transporteur = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="chauffeurs"
    )

    nom = models.CharField(
        max_length=100
    )

    telephone = models.CharField(
        max_length=20,
        unique=True
    )

    numero_permis = models.CharField(
        max_length=50
    )

    date_expiration_permis = models.DateField(
        blank=True,
        null=True
    )

    code_acces = models.CharField(
        max_length=20,
        default="",
        blank=True
    )

    photo = models.ImageField(
        upload_to="chauffeurs/",
        blank=True,
        null=True
    )

    pays = models.CharField(
        max_length=2,
        choices=PAYS_CEDEAO_CHOICES,
        default="ML"
    )

    disponible = models.BooleanField(
        default=True
    )

    actif = models.BooleanField(
        default=True
    )

    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True
    )

    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True
    )

    position_updated_at = models.DateTimeField(
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    @property
    def affectation_active(self):
        """Affectation en cours (celle qui n'a pas de date de fin), sinon None."""
        return self.affectations.filter(
            date_fin__isnull=True
        ).select_related("camion").first()

    @property
    def camion_actuel(self):
        affectation = self.affectation_active
        return affectation.camion if affectation else None

    def __str__(self):
        return self.nom


class AffectationChauffeur(models.Model):
    """Historise quel chauffeur conduit quel camion, et depuis quand.

    Une affectation sans `date_fin` est l'affectation courante. Clôturer une
    affectation (renseigner `date_fin`) la conserve dans l'historique au lieu
    de l'écraser, ce qui permet de relire a posteriori qui conduisait un camion
    au moment d'une mission ou d'un point GPS.
    """

    chauffeur = models.ForeignKey(
        Chauffeur,
        on_delete=models.CASCADE,
        related_name="affectations"
    )

    camion = models.ForeignKey(
        Camion,
        on_delete=models.CASCADE,
        related_name="affectations"
    )

    date_debut = models.DateTimeField(
        default=timezone.now
    )

    date_fin = models.DateTimeField(
        null=True,
        blank=True
    )

    commentaire = models.CharField(
        max_length=255,
        blank=True,
        default=""
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        ordering = ["-date_debut"]
        constraints = [
            # Un camion n'a qu'un seul chauffeur à un instant donné...
            models.UniqueConstraint(
                fields=["camion"],
                condition=models.Q(date_fin__isnull=True),
                name="unique_affectation_active_par_camion"
            ),
            # ...et un chauffeur ne conduit qu'un seul camion à la fois.
            models.UniqueConstraint(
                fields=["chauffeur"],
                condition=models.Q(date_fin__isnull=True),
                name="unique_affectation_active_par_chauffeur"
            ),
        ]

    @property
    def active(self):
        return self.date_fin is None

    def cloturer(self, date_fin=None):
        """Termine l'affectation sans la supprimer de l'historique."""
        if self.date_fin is not None:
            return self

        self.date_fin = date_fin or timezone.now()
        self.save(update_fields=["date_fin"])
        return self

    def __str__(self):
        periode = (
            "en cours" if self.active
            else f"jusqu'au {self.date_fin:%d/%m/%Y}"
        )
        return f"{self.chauffeur.nom} → {self.camion.immatriculation} ({periode})"


class DemandeTransport(models.Model):

    TYPE_CAMION = TYPE_CAMION_CHOICES


    STATUT = (
        ('OUVERTE', 'Ouverte'),
        ('EN_COURS', 'En cours'),
        ('TERMINEE', 'Terminée'),
        ('ANNULEE', 'Annulée'),
    )


    client = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="demandes_transport"
    )


    type_camion = models.CharField(
        max_length=50,
        choices=TYPE_CAMION
    )

    # Même référentiel/mêmes règles que Camion.format_camion — permet au
    # matching (proposer_camions_pour_demande) de comparer un format
    # demandé à celui des camions candidats, pas seulement le type.
    # Optionnel : un client qui ne sait pas préciser laisse vide.
    format_camion = models.CharField(
        max_length=30,
        choices=FORMAT_CAMION_CHOICES,
        blank=True,
        default=""
    )

    format_autre = models.CharField(
        max_length=100,
        blank=True,
        default=""
    )


    nombre_camions = models.PositiveIntegerField(
        default=1
    )


    ville_depart = models.CharField(
        max_length=100
    )


    ville_arrivee = models.CharField(
        max_length=100
    )


    description = models.TextField(
        blank=True,
        null=True
    )


    quantite = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Quantité à transporter"
    )

    pays_depart = models.CharField(
        max_length=2,
        choices=PAYS_CEDEAO_CHOICES,
        default="ML"
    )

    pays_arrivee = models.CharField(
        max_length=2,
        choices=PAYS_CEDEAO_CHOICES,
        default="ML"
    )

    latitude_depart = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True
    )

    longitude_depart = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True
    )

    latitude_arrivee = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True
    )

    longitude_arrivee = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True
    )

    unite = models.CharField(
        max_length=20,
        default="litres"
    )


    date_chargement = models.DateField()


    prix_propose = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        blank=True,
        null=True
    )


    statut = models.CharField(
        max_length=20,
        choices=STATUT,
        default="OUVERTE"
    )


    date_creation = models.DateTimeField(
        auto_now_add=True
    )


    def __str__(self):
        return f"{self.ville_depart} - {self.ville_arrivee}"
    
class Proposition(models.Model):

    class Statut(models.TextChoices):
        EN_ATTENTE = "EN_ATTENTE", "En attente"
        ACCEPTEE = "ACCEPTEE", "Acceptée"
        REFUSEE = "REFUSEE", "Refusée"
        ANNULEE = "ANNULEE", "Annulée"

    demande = models.ForeignKey(
        DemandeTransport,
        on_delete=models.CASCADE,
        related_name="propositions"
    )

    transporteur = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="propositions"
    )

    prix = models.DecimalField(
        max_digits=12,
        decimal_places=2
    )

    message = models.TextField(
        blank=True,
        null=True
    )

    observations = models.TextField(
        blank=True,
        null=True
    )

    delai_depart = models.DateTimeField(
        blank=True,
        null=True
    )

    distance_estimee_km = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True
    )

    score_matching = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        help_text="Score de matching pour le tri des propositions"
    )

    valide_jusquau = models.DateTimeField(
        blank=True,
        null=True
    )

    statut = models.CharField(
        max_length=20,
        choices=Statut.choices,
        default=Statut.EN_ATTENTE
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["demande", "transporteur"],
                name="unique_proposition_transporteur_par_demande"
            )
        ]

    def __str__(self):
        return f"Proposition #{self.pk}"
    

class PropositionCamion(models.Model):

    proposition = models.ForeignKey(
        Proposition,
        on_delete=models.CASCADE,
        related_name="camions"
    )

    camion = models.ForeignKey(
        Camion,
        on_delete=models.CASCADE
    )

    chauffeur = models.ForeignKey(
        Chauffeur,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    ordre = models.PositiveIntegerField(
        default=1
    )
    heure_depart = models.DateTimeField(
        null=True,
        blank=True
    )

    heure_arrivee = models.DateTimeField(
        null=True,
        blank=True
    )

    statut = models.CharField(
        max_length=20,
        default="EN_ATTENTE"
    )
    class Meta:
        unique_together = (
            'proposition',
            'camion'
        )

    def __str__(self):
        return self.camion.immatriculation

class Mission(models.Model):

    class Statut(models.TextChoices):
        PLANIFIEE = "PLANIFIEE", "Planifiée"
        EN_COURS = "EN_COURS", "En cours"
        TERMINEE = "TERMINEE", "Terminée"
        ANNULEE = "ANNULEE", "Annulée"


    demande = models.ForeignKey(
        DemandeTransport,
        on_delete=models.CASCADE,
        related_name="missions"
    )


    proposition = models.OneToOneField(
        Proposition,
        on_delete=models.CASCADE,
        related_name="mission"
    )


    client = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="missions_client"
    )


    transporteur = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="missions_transporteur"
    )


    prix_final = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        blank=True,
        null=True
    )


    statut = models.CharField(
        max_length=20,
        choices=Statut.choices,
        default=Statut.PLANIFIEE
    )


    date_creation = models.DateTimeField(
        auto_now_add=True
    )


    date_modification = models.DateTimeField(
        auto_now=True
    )


    date_depart = models.DateTimeField(
        blank=True,
        null=True
    )


    date_arrivee = models.DateTimeField(
        blank=True,
        null=True
    )


    observations = models.TextField(
        blank=True,
        null=True
    )


    class Meta:
        ordering = [
            "-date_creation"
        ]


    def __str__(self):
        return f"Mission #{self.id} - {self.statut}"
    
class MissionCamion(models.Model):

    class Statut(models.TextChoices):
        PREVU = "PREVU", "Prévu"
        AU_CHARGEMENT = "AU_CHARGEMENT", "Au chargement"
        CHARGE = "CHARGE", "Chargé"
        EN_ROUTE = "EN_ROUTE", "En route"
        ARRIVE = "ARRIVE", "Arrivé"
        LIVRE = "LIVRE", "Livré"
        PANNE = "PANNE", "En panne"
        ANNULE = "ANNULE", "Annulé"

    mission = models.ForeignKey(
        Mission,
        on_delete=models.CASCADE,
        related_name="camions"
    )

    camion = models.ForeignKey(
        Camion,
        on_delete=models.CASCADE,
        related_name="missions"
    )

    chauffeur = models.ForeignKey(
        Chauffeur,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="missions"
    )

    ordre = models.PositiveIntegerField(default=1)

    statut = models.CharField(
        max_length=20,
        choices=Statut.choices,
        default=Statut.PREVU
    )

    heure_depart = models.DateTimeField(
        null=True,
        blank=True
    )

    heure_arrivee = models.DateTimeField(
        null=True,
        blank=True
    )

    observations = models.TextField(
        blank=True,
        null=True
    )

    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ["ordre"]
        constraints = [
            models.UniqueConstraint(
                fields=["mission", "camion"],
                name="unique_camion_par_mission"
            )
        ]

    def __str__(self):
        return f"{self.camion.immatriculation} - {self.mission}"
    


class HistoriqueMission(models.Model):

    mission_camion = models.ForeignKey(
        MissionCamion,
        on_delete=models.CASCADE,
        related_name="historiques"
    )

    ancien_statut = models.CharField(
        max_length=30,
        blank=True,
        null=True
    )

    nouveau_statut = models.CharField(
        max_length=30
    )

    commentaire = models.TextField(
        blank=True,
        null=True
    )

    date = models.DateTimeField(
        auto_now_add=True
    )


    class Meta:
        ordering = ['-date']


    def __str__(self):
        return f"{self.mission_camion} - {self.nouveau_statut}"


class PositionGPS(models.Model):

    mission_camion = models.ForeignKey(
        MissionCamion,
        on_delete=models.CASCADE,
        related_name="positions"
    )

    latitude = models.DecimalField(
        max_digits=10,
        decimal_places=7
    )

    longitude = models.DecimalField(
        max_digits=10,
        decimal_places=7
    )

    vitesse = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        null=True,
        blank=True
    )

    precision = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        null=True,
        blank=True
    )

    batterie = models.IntegerField(
        null=True,
        blank=True
    )

    date = models.DateTimeField(
        auto_now_add=True
    )

    source = models.CharField(
        max_length=20,
        choices=[('GPS', 'GPS'), ('TELEPHONE', 'Téléphone')],
        default='GPS'
    )

    telephone_chauffeur = models.CharField(
        max_length=20,
        blank=True,
        null=True
    )

    class Meta:
        ordering = ['-date']

    def __str__(self):
        return f"{self.mission_camion} - {self.date}"


class Notification(models.Model):
    """Notification interne (in-app). Pas de push Firebase pour l'instant —
    juste une liste que l'utilisateur consulte dans l'app, cf. TODO produit."""

    class Type(models.TextChoices):
        NOUVELLE_DEMANDE = "NOUVELLE_DEMANDE", "Nouvelle demande"
        NOUVELLE_PROPOSITION = "NOUVELLE_PROPOSITION", "Nouvelle proposition"
        PROPOSITION_ACCEPTEE = "PROPOSITION_ACCEPTEE", "Proposition acceptée"
        PROPOSITION_REFUSEE = "PROPOSITION_REFUSEE", "Proposition refusée"
        MISSION_CREEE = "MISSION_CREEE", "Mission créée"
        MISSION_DEMARREE = "MISSION_DEMARREE", "Mission démarrée"
        MISSION_TERMINEE = "MISSION_TERMINEE", "Mission terminée"
        MISSION_ANNULEE = "MISSION_ANNULEE", "Mission annulée"
        PAIEMENT_ENCAISSE = "PAIEMENT_ENCAISSE", "Paiement encaissé"
        PAIEMENT_SECURISE = "PAIEMENT_SECURISE", "Paiement sécurisé"
        PAIEMENT_LIBERE = "PAIEMENT_LIBERE", "Paiement libéré"
        PAIEMENT_VERSE = "PAIEMENT_VERSE", "Paiement versé"
        PAIEMENT_REMBOURSE = "PAIEMENT_REMBOURSE", "Paiement remboursé"
        PAIEMENT_ECHEC = "PAIEMENT_ECHEC", "Échec du paiement"
        LITIGE_OUVERT = "LITIGE_OUVERT", "Litige ouvert"
        LITIGE_RESOLU = "LITIGE_RESOLU", "Litige résolu"

    destinataire = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="notifications"
    )

    type_notification = models.CharField(
        max_length=30,
        choices=Type.choices
    )

    message = models.CharField(
        max_length=255
    )

    # Référence vivante vers la proposition concernée (types NOUVELLE_
    # PROPOSITION / PROPOSITION_ACCEPTEE / PROPOSITION_REFUSEE) — `message`
    # est un texte figé au moment de la création, il peut diverger de l'état
    # actuel de la proposition (prix affiché ailleurs différent, proposition
    # supprimée...). `null=True` : les autres types de notification n'ont
    # pas de proposition, et `on_delete=SET_NULL` pour qu'une proposition
    # supprimée n'efface pas l'historique de notifications, seulement le lien.
    proposition = models.ForeignKey(
        Proposition,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="notifications"
    )

    # Même pattern que `proposition` ci-dessus, pour la même raison : un
    # montant/statut de paiement figé dans `message` dériverait de l'état réel
    # de `Paiement` (ex. après validation admin ou résolution d'un litige).
    # `Paiement` est défini plus bas dans ce fichier — chaîne de classe pour
    # éviter un forward-reference direct.
    paiement = models.ForeignKey(
        "Paiement",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="notifications"
    )

    lue = models.BooleanField(
        default=False
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.destinataire} - {self.type_notification}"


# ==========================
# PAIEMENTS
# ==========================
#
# Un seul `Paiement` par `Mission`, quel que soit le mode (CARTE ou MANUEL) :
# après encaissement, AfriFlotte détient l'argent dans les deux cas (via le
# PSP pour CARTE, via un agent AfriFlotte pour MANUEL — pas le transporteur),
# donc les deux modes convergent vers la même machine à états de séquestre.
#
# EN_ATTENTE -> ENCAISSE -> SECURISE -> LIBERE -> VERSE
#                                  \-> REMBOURSE
# `litige_en_cours=True` bloque LIBERE/VERSE/REMBOURSE tant qu'un Litige lié
# n'est pas résolu (cf. `resoudre_litige_service` dans services.py).
#
# `devise`/`commission_taux` sont volontairement stockés ici (contrairement à
# la convention du reste du projet — cf. `devise_pour_pays`, jamais stocké
# sur DemandeTransport/Proposition/Mission) : ce sont des lignes financières
# immuables, pas des libellés d'affichage — elles ne doivent pas changer de
# sens si `pays_depart` ou le taux de commission évoluent après coup.
class Paiement(models.Model):

    class Mode(models.TextChoices):
        CARTE = "CARTE", "Carte bancaire"
        MOBILE = "MOBILE", "Mobile Money"
        MANUEL = "MANUEL", "Manuel (main à main)"

    class Statut(models.TextChoices):
        EN_ATTENTE = "EN_ATTENTE", "En attente"
        ENCAISSE = "ENCAISSE", "Encaissé"
        SECURISE = "SECURISE", "Sécurisé"
        LIBERE = "LIBERE", "Libéré"
        VERSE = "VERSE", "Versé au transporteur"
        REMBOURSE = "REMBOURSE", "Remboursé"
        ECHEC = "ECHEC", "Échec"

    mission = models.OneToOneField(
        Mission,
        on_delete=models.CASCADE,
        related_name="paiement"
    )

    mode = models.CharField(
        max_length=10,
        choices=Mode.choices
    )

    montant_total = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text="Copie de mission.prix_final au moment de la création — ligne financière figée."
    )

    devise = models.CharField(
        max_length=3,
        help_text="Copie figée de devise_pour_pays(mission.demande.pays_depart) au moment de la création."
    )

    montant_xof_facture = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        null=True,
        blank=True,
        help_text=(
            "Équivalent XOF réellement envoyé à PayDunya (celui-ci ne facture "
            "qu'en XOF), figé au moment de la conversion — cf. "
            "constants.convertir_vers_xof. Nul quand `devise` est déjà XOF "
            "(montant_total suffit alors) ; ne pas recalculer depuis "
            "TAUX_VERS_XOF pour un remboursement, ce taux peut changer."
        ),
    )

    commission_taux = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        help_text="Taux de commission AfriFlotte (%) au moment de la création, ex. 5.00."
    )

    commission_montant = models.DecimalField(
        max_digits=12,
        decimal_places=2
    )

    montant_transporteur = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text="montant_total - commission_montant, dû au transporteur."
    )

    statut = models.CharField(
        max_length=20,
        choices=Statut.choices,
        default=Statut.EN_ATTENTE
    )

    # Agent AfriFlotte (User.type_compte == 'AGENT') qui a physiquement
    # encaissé l'argent du client — uniquement en mode MANUEL.
    agent = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="paiements_encaisses"
    )

    reference_externe = models.CharField(
        max_length=100,
        blank=True,
        default="",
        help_text="Référence de transaction PSP (CARTE) ou référence/reçu manuel (MANUEL)."
    )

    # Métadonnées d'affichage uniquement (mode CARTE) — jamais le numéro
    # complet ni le CVV, qui ne transitent jamais par Django (cf.
    # core/gateway_paiement.py). Servent juste à afficher "Visa •••• 4242
    # (08/29)" comme le ferait une page de facturation type Stripe/Claude.
    carte_marque = models.CharField(
        max_length=20,
        blank=True,
        default=""
    )

    carte_dernier4 = models.CharField(
        max_length=4,
        blank=True,
        default=""
    )

    carte_expiration = models.CharField(
        max_length=5,
        blank=True,
        default="",
        help_text="Format MM/AA, affichage uniquement."
    )

    litige_en_cours = models.BooleanField(
        default=False
    )

    motif_remboursement = models.TextField(
        blank=True,
        default=""
    )

    date_encaissement = models.DateTimeField(null=True, blank=True)
    date_securisation = models.DateTimeField(null=True, blank=True)
    date_liberation = models.DateTimeField(null=True, blank=True)
    date_versement = models.DateTimeField(null=True, blank=True)
    date_remboursement = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Paiement #{self.pk} - {self.mission_id} - {self.statut}"


class PreuvePaiement(models.Model):
    """Justificatif attaché à un paiement — réutilisé pour la preuve
    d'encaissement (client/agent), la preuve de versement au transporteur et
    la preuve de remboursement, plutôt que trois modèles quasi identiques."""

    class TypePreuve(models.TextChoices):
        RECU_ESPECES = "RECU_ESPECES", "Reçu espèces"
        SIGNATURE_CLIENT = "SIGNATURE_CLIENT", "Signature client"
        CAPTURE_PSP = "CAPTURE_PSP", "Capture confirmation PSP"
        JUSTIFICATIF_VIREMENT = "JUSTIFICATIF_VIREMENT", "Justificatif de virement"
        JUSTIFICATIF_REMBOURSEMENT = "JUSTIFICATIF_REMBOURSEMENT", "Justificatif de remboursement"
        AUTRE = "AUTRE", "Autre"

    paiement = models.ForeignKey(
        Paiement,
        on_delete=models.CASCADE,
        related_name="preuves"
    )

    fichier = models.ImageField(
        upload_to="preuves_paiement/"
    )

    type_preuve = models.CharField(
        max_length=30,
        choices=TypePreuve.choices
    )

    ajoute_par = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True
    )

    commentaire = models.CharField(
        max_length=255,
        blank=True,
        default=""
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Preuve {self.type_preuve} - paiement #{self.paiement_id}"


class Litige(models.Model):

    class Statut(models.TextChoices):
        OUVERT = "OUVERT", "Ouvert"
        EN_EXAMEN = "EN_EXAMEN", "En examen"
        RESOLU_CLIENT = "RESOLU_CLIENT", "Résolu en faveur du client"
        RESOLU_TRANSPORTEUR = "RESOLU_TRANSPORTEUR", "Résolu en faveur du transporteur"
        REJETE = "REJETE", "Rejeté"

    paiement = models.ForeignKey(
        Paiement,
        on_delete=models.CASCADE,
        related_name="litiges"
    )

    ouvert_par = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="litiges_ouverts"
    )

    motif = models.TextField()

    statut = models.CharField(
        max_length=20,
        choices=Statut.choices,
        default=Statut.OUVERT
    )

    resolution_commentaire = models.TextField(
        blank=True,
        default=""
    )

    resolu_par = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="litiges_resolus"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    resolu_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Litige #{self.pk} - paiement #{self.paiement_id} - {self.statut}"
