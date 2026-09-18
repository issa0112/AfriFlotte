import base64
from decimal import Decimal
from datetime import timedelta
from unittest.mock import Mock, patch

from django.core import mail
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from .models import (
    AffectationChauffeur,
    Camion,
    Chauffeur,
    DemandeTransport,
    ImageCamion,
    Litige,
    Mission,
    MissionCamion,
    Notification,
    Paiement,
    PositionGPS,
    PreuvePaiement,
    Proposition,
    PropositionCamion,
    User,
)
from .telephone import (
    TelephoneInvalide,
    correspond_localement,
    formater_local,
    valider_et_normaliser,
)

# PNG 1x1 transparent minimal, valide pour Pillow/ImageField.
_PNG_1X1 = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk"
    "+A8AAQUBAScY42YAAAAASUVORK5CYII="
)


def _fichier_image(nom="photo.png"):
    return SimpleUploadedFile(nom, _PNG_1X1, content_type="image/png")
from .services import (
    accepter_proposition_service,
    calculer_commission,
    classifier_fraicheur,
    confirmer_paiement_carte_service,
    creer_paiement_service,
    distance_km,
    encaisser_paiement_manuel_service,
    initier_paiement_carte_service,
    liberer_paiement_service,
    marquer_verse_service,
    notifier,
    ouvrir_litige_service,
    proposer_camions_pour_demande,
    rembourser_paiement_service,
    resoudre_litige_service,
    refuser_proposition_service,
    resoudre_position_camion,
    terminer_mission_service,
    valider_paiement_manuel_service,
)
from .serializers import (
    CamionSerializer,
    DemandeTransportSerializer,
    MissionSerializer,
    PropositionSerializer,
)
from .constants import (
    PAYS_CEDEAO,
    PAYS_CEDEAO_CHOICES,
    canaux_paydunya_pour_pays,
    convertir_vers_xof,
    devise_pour_pays,
    indicatif_pour_pays,
    moyens_paiement_paydunya,
)
from .gateway_paiement import PayDunyaGatewayAdapter, PayDunyaInvalide


class PaiementMultiPaysConfigurationTests(TestCase):
    @override_settings(
        COMMISSION_AFRIFLOTTE_SEUIL=3000000,
        COMMISSION_AFRIFLOTTE_TAUX=5,
        COMMISSION_AFRIFLOTTE_TAUX_SUPERIEUR=4,
    )
    def test_commission_par_paliers(self):
        self.assertEqual(calculer_commission(1000000), (Decimal("50000.00"), Decimal("950000.00")))
        self.assertEqual(calculer_commission(3000000), (Decimal("150000.00"), Decimal("2850000.00")))
        self.assertEqual(calculer_commission(3000001), (Decimal("120000.04"), Decimal("2880000.96")))

    def test_paydunya_expose_cartes_partout_et_mobile_money_seulement_ou_il_lopere(self):
        # ML/SN reflètent les méthodes réellement autorisées sur le compte
        # marchand PayDunya d'AfriFlotte (pas juste ce que PayDunya documente
        # publiquement) : pas de Moov Money au Mali, pas d'Orange Money au
        # Sénégal sur ce compte précis.
        self.assertEqual(
            moyens_paiement_paydunya("ML"),
            {"cartes": ("VISA", "MASTERCARD"), "mobile_money": ("Orange Money",)},
        )
        self.assertEqual(
            moyens_paiement_paydunya("SN")["mobile_money"],
            ("Expresso", "Free Money", "Wave", "Djamo"),
        )
        self.assertEqual(
            moyens_paiement_paydunya("GH"),
            {"cartes": ("VISA", "MASTERCARD"), "mobile_money": ()},
        )
        self.assertEqual(moyens_paiement_paydunya("XX"), {"cartes": (), "mobile_money": ()})

    def test_conversion_vers_xof(self):
        self.assertEqual(convertir_vers_xof(Decimal("50000"), "XOF"), Decimal("50000"))
        self.assertEqual(convertir_vers_xof(1000, "GHS"), Decimal("49000"))
        with self.assertRaises(ValueError):
            convertir_vers_xof(100, "USD")

    def test_canaux_paydunya_pour_pays(self):
        self.assertEqual(canaux_paydunya_pour_pays("ML"), ("card", "orange-money-mali"))
        self.assertEqual(
            canaux_paydunya_pour_pays("SN"),
            ("card", "expresso-senegal", "free-money-senegal", "wave-senegal", "djamo"),
        )
        self.assertEqual(canaux_paydunya_pour_pays("GH"), ("card",))
        self.assertIsNone(canaux_paydunya_pour_pays("XX"))


class DemandeTransportSerializerTests(TestCase):
    def test_serializer_exposes_friendly_fields_for_client_ui(self):
        user = User.objects.create_user(
            username='client-ui',
            password='secret123',
            telephone='0600000010',
            type_compte='ENTREPRISE',
        )
        demande = DemandeTransport.objects.create(
            client=user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            description='Essence',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
        )

        serializer = DemandeTransportSerializer(demande)
        data = serializer.data

        self.assertEqual(data['depart'], 'Bamako')
        self.assertEqual(data['destination'], 'Ségou')
        self.assertEqual(data['produit'], 'Essence')
        self.assertEqual(data['nombre_camions'], 1)

    def test_serializer_expose_pays_et_devise(self):
        user = User.objects.create_user(
            username='client-devise-demande',
            password='secret123',
            telephone='0600000011',
            type_compte='ENTREPRISE',
        )
        demande = DemandeTransport.objects.create(
            client=user,
            type_camion='CITERNE',
            ville_depart='Lagos',
            ville_arrivee='Cotonou',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
            pays_depart='NG',
            pays_arrivee='BJ',
        )

        data = DemandeTransportSerializer(demande).data

        self.assertEqual(data['pays_depart'], 'NG')
        self.assertEqual(data['pays_arrivee'], 'BJ')
        self.assertEqual(data['devise'], 'NGN')


class FormatCamionValidationTests(TestCase):
    """`valider_format_camion` (core/serializers.py), branché sur
    `CamionSerializer` et `DemandeTransportSerializer` : le format doit
    correspondre au type (une classe de litrage n'a pas de sens pour un
    plateau), et "Autre" exige une saisie libre."""

    def setUp(self):
        self.transporteur = User.objects.create_user(
            username='transporteur-format',
            password='secret123',
            telephone='0600000060',
            type_compte='TRANSPORTEUR',
        )

    def _donnees_camion(self, **overrides):
        data = {
            'type_camion': 'PLATEAU',
            'immatriculation': 'FMT-001',
            'capacite': '20000',
        }
        data.update(overrides)
        return data

    def test_format_conteneur_valide_pour_plateau(self):
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='PLATEAU', format_camion='40_PIEDS',
        ))
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_format_citerne_refuse_pour_plateau(self):
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='PLATEAU', format_camion='CITERNE_20000L',
        ))
        self.assertFalse(serializer.is_valid())
        self.assertIn('format_camion', serializer.errors)

    def test_format_litrage_valide_pour_citerne(self):
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='CITERNE', format_camion='CITERNE_20000L',
        ))
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_format_citerne_impose_la_capacite_correspondante(self):
        # `capacite` tapée à 20000 alors que le format dit 43000 L : le
        # format doit gagner, pas la saisie manuelle divergente — sinon le
        # camion afficherait une capacité incohérente avec son propre
        # format partout où l'un des deux est montré isolément.
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='CITERNE', format_camion='CITERNE_43000L',
            capacite='20000',
        ))
        self.assertTrue(serializer.is_valid(), serializer.errors)
        self.assertEqual(serializer.validated_data['capacite'], 43000)

    def test_format_config_essieux_valide_pour_benne(self):
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='BENNE', format_camion='BENNE_8X4',
        ))
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_format_benne_impose_le_nombre_essieux_correspondant(self):
        # `essieux` tapé à 2 alors que le format 8×4 en implique 4 : même
        # logique que pour la capacité citerne — le format gagne.
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='BENNE', format_camion='BENNE_8X4', essieux=2,
        ))
        self.assertTrue(serializer.is_valid(), serializer.errors)
        self.assertEqual(serializer.validated_data['essieux'], 4)

    def test_format_citerne_refuse_pour_benne(self):
        # Une classe de litrage n'a pas de sens pour une benne, dont la
        # capacité se définit par configuration d'essieux (BENNE_4X2/6X4/8X4).
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='BENNE', format_camion='CITERNE_20000L',
        ))
        self.assertFalse(serializer.is_valid())
        self.assertIn('format_camion', serializer.errors)

    def test_format_refuse_pour_porte_engin(self):
        # PORTE_ENGIN n'apparaît pas dans FORMATS_PAR_TYPE : aucun format,
        # pas même "AUTRE", n'est valide pour ce type.
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='PORTE_ENGIN', format_camion='AUTRE', format_autre='Spécial',
        ))
        self.assertFalse(serializer.is_valid())
        self.assertIn('format_camion', serializer.errors)

    def test_format_vide_toujours_valide(self):
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='BENNE', format_camion='',
        ))
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_autre_sans_precision_refuse(self):
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='PLATEAU', format_camion='AUTRE', format_autre='',
        ))
        self.assertFalse(serializer.is_valid())
        self.assertIn('format_autre', serializer.errors)

    def test_autre_avec_precision_valide(self):
        serializer = CamionSerializer(data=self._donnees_camion(
            type_camion='PLATEAU', format_camion='AUTRE', format_autre='Rehaussé',
        ))
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_demande_transport_meme_validation(self):
        payload = {
            'client': self.transporteur.id,
            'type_camion': 'PLATEAU',
            'format_camion': 'CITERNE_20000L',
            'ville_depart': 'Bamako',
            'ville_arrivee': 'Kayes',
            'description': 'Ciment',
            'quantite': '5000',
            'unite': 'tonnes',
            'date_chargement': '2026-08-08',
        }
        serializer = DemandeTransportSerializer(data=payload)
        self.assertFalse(serializer.is_valid())
        self.assertIn('format_camion', serializer.errors)

    def test_changer_le_type_seul_rejette_si_ancien_format_devient_invalide(self):
        # PATCH partielle qui ne touche qu'au type : `format_camion` n'est
        # pas dans le payload, donc `validate` retombe sur l'ancienne valeur
        # de l'instance (`CITERNE_20000L`) — qui n'a plus de sens pour
        # PLATEAU. Le serveur doit rejeter plutôt que d'enregistrer un
        # camion PLATEAU avec un format de citerne, ou pire, appliquer la
        # dérivation `capacite`/`essieux` d'un autre type par erreur.
        camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            format_camion='CITERNE_20000L',
            immatriculation='FMT-CHAIN-1',
            capacite=20000,
        )

        serializer = CamionSerializer(
            instance=camion, data={'type_camion': 'PLATEAU'}, partial=True,
        )

        self.assertFalse(serializer.is_valid())
        self.assertIn('format_camion', serializer.errors)

    def test_changer_le_type_et_le_format_ensemble_fonctionne(self):
        # Même point de départ, mais le format est envoyé avec le nouveau
        # type dans la même requête (ce que fait l'app Flutter) : doit
        # passer, et la dérivation doit suivre le NOUVEAU type/format.
        camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            format_camion='CITERNE_20000L',
            immatriculation='FMT-CHAIN-2',
            capacite=20000,
        )

        serializer = CamionSerializer(
            instance=camion,
            data={'type_camion': 'BENNE', 'format_camion': 'BENNE_6X4'},
            partial=True,
        )

        self.assertTrue(serializer.is_valid(), serializer.errors)
        self.assertEqual(serializer.validated_data['essieux'], 3)


class PaysCedeaoTests(TestCase):
    """Référentiel `core/constants.py` — miroir Flutter dans
    `afriflotte_app/lib/constants/pays_cedeao.dart`."""

    def test_quinze_pays_cedeao_et_quinze_pays_ouverts(self):
        self.assertEqual(len(PAYS_CEDEAO), 15)
        self.assertEqual(len(PAYS_CEDEAO_CHOICES), 15)

    def test_codes_uniques(self):
        codes = [code for code, _nom, _devise, _indicatif in PAYS_CEDEAO]
        self.assertEqual(len(codes), len(set(codes)))

    def test_indicatif_telephonique(self):
        self.assertEqual(indicatif_pour_pays('ML'), '+223')
        self.assertEqual(indicatif_pour_pays('SN'), '+221')
        self.assertEqual(indicatif_pour_pays('NG'), '+234')
        self.assertIsNone(indicatif_pour_pays('XX'))

    def test_devise_zone_uemoa(self):
        # Les 8 membres UEMOA partagent le XOF — dont Guinée-Bissau, membre
        # non-francophone facile à oublier.
        for code in ('BJ', 'BF', 'CI', 'GW', 'ML', 'NE', 'SN', 'TG'):
            self.assertEqual(devise_pour_pays(code), 'XOF')

    def test_devise_hors_uemoa(self):
        self.assertEqual(devise_pour_pays('GH'), 'GHS')
        self.assertEqual(devise_pour_pays('NG'), 'NGN')
        self.assertEqual(devise_pour_pays('GN'), 'GNF')
        self.assertEqual(devise_pour_pays('LR'), 'LRD')
        self.assertEqual(devise_pour_pays('SL'), 'SLE')
        self.assertEqual(devise_pour_pays('GM'), 'GMD')
        self.assertEqual(devise_pour_pays('CV'), 'CVE')

    def test_code_inconnu_retourne_none(self):
        """Pas de repli silencieux sur XOF : un code invalide doit remonter
        comme une erreur exploitable plutôt qu'afficher une devise fausse."""
        self.assertIsNone(devise_pour_pays('XX'))
        self.assertIsNone(devise_pour_pays(None))


class DeviseDeriveeTests(TestCase):
    """La devise n'est jamais stockée : `DemandeTransportSerializer`,
    `PropositionSerializer` et `MissionSerializer` la dérivent tous de
    `pays_depart` via `devise_pour_pays`, jamais d'une deuxième source."""

    def setUp(self):
        self.transporteur = User.objects.create_user(
            username='transporteur-devise',
            password='secret123',
            telephone='0600000070',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-devise',
            password='secret123',
            telephone='0600000071',
            type_compte='ENTREPRISE',
        )
        self.demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Accra',
            ville_arrivee='Lomé',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
            pays_depart='GH',
            pays_arrivee='TG',
        )

    def test_proposition_expose_la_devise_de_sa_demande(self):
        proposition = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.transporteur,
            prix=150000,
        )

        data = PropositionSerializer(proposition).data

        self.assertEqual(data['devise'], 'GHS')
        self.assertEqual(data['pays_depart'], 'GH')
        self.assertEqual(data['pays_arrivee'], 'TG')

    def test_mission_expose_la_devise_de_sa_demande(self):
        proposition = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.transporteur,
            prix=150000,
        )
        mission = Mission.objects.create(
            demande=self.demande,
            proposition=proposition,
            client=self.client_user,
            transporteur=self.transporteur,
            prix_final=150000,
        )

        data = MissionSerializer(mission).data

        self.assertEqual(data['devise'], 'GHS')
        self.assertEqual(data['pays_depart'], 'GH')
        self.assertEqual(data['pays_arrivee'], 'TG')


class PaysUserChauffeurTests(TestCase):
    """`User.pays`/`Chauffeur.pays` — même traitement régional que Camion/
    DemandeTransport, plus l'indicatif téléphonique composé côté Flutter
    (auth_screen.dart/ajouter_chauffeur.dart envoient déjà le numéro complet,
    donc rien à composer côté backend — juste stocker/exposer `pays`)."""

    def setUp(self):
        self.client = APIClient()

    def test_inscription_avec_pays(self):
        response = self.client.post(
            '/api/register/',
            {
                'username': '+2250700000001',
                'telephone': '+2250700000001',
                'password': 'secret123',
                'email': 'transporteur-ci@example.com',
                'type_compte': 'TRANSPORTEUR',
                'pays': 'CI',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        user = User.objects.get(telephone='+2250700000001')
        self.assertEqual(user.pays, 'CI')

    def test_inscription_refuse_type_compte_admin_ou_agent(self):
        """/api/register/ est public (aucune authentification) : sans ce
        refus, n'importe qui pouvait s'auto-créer un compte ADMIN ou AGENT
        juste en le demandant dans le payload d'inscription."""
        for suffixe, type_compte in enumerate(('ADMIN', 'AGENT'), start=1):
            telephone = f'+22507000009{suffixe}'
            response = self.client.post(
                '/api/register/',
                {
                    'username': telephone,
                    'telephone': telephone,
                    'password': 'secret123',
                    'type_compte': type_compte,
                },
                format='json',
            )

            self.assertEqual(response.status_code, 400)
            self.assertFalse(User.objects.filter(type_compte=type_compte).exists())

    def test_inscription_sans_pays_retombe_sur_ml(self):
        """`UserSerializer.create()` doit passer `.get('pays', 'ML')`, pas
        `.get('pays')` — un `None` explicite écraserait le `default='ML'` du
        modèle et casserait la contrainte NOT NULL (`pays` n'a pas `null=True`)."""
        response = self.client.post(
            '/api/register/',
            {
                'username': '+22376000002',
                'telephone': '+22376000002',
                'password': 'secret123',
                'email': 'entreprise-ml@example.com',
                'type_compte': 'ENTREPRISE',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        user = User.objects.get(telephone='+22376000002')
        self.assertEqual(user.pays, 'ML')

    def test_login_expose_pays(self):
        User.objects.create_user(
            username='login-pays',
            password='secret123',
            telephone='+221070000003',
            type_compte='ENTREPRISE',
            pays='SN',
        )

        response = self.client.post(
            '/api/login/',
            {'telephone': '+221070000003', 'password': 'secret123'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['user']['pays'], 'SN')

    def test_login_expose_email_et_adresse(self):
        """Régression : la page profil transporteur/client lit `email` et
        `adresse` sur l'objet `user` renvoyé à la connexion, mais ces deux
        champs — qui existent bien sur le modèle — n'étaient jamais inclus
        dans la réponse de login, donc toujours affichés comme "Non renseigné"
        côté Flutter quelle que soit leur vraie valeur en base."""
        User.objects.create_user(
            username='login-email',
            password='secret123',
            telephone='0600000099',
            type_compte='TRANSPORTEUR',
            email='iso@example.com',
            adresse='Quartier ACI 2000, Bamako',
        )

        response = self.client.post(
            '/api/login/',
            {'telephone': '0600000099', 'password': 'secret123'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['user']['email'], 'iso@example.com')
        self.assertEqual(
            response.data['user']['adresse'], 'Quartier ACI 2000, Bamako'
        )

    def test_chauffeur_expose_pays(self):
        transporteur = User.objects.create_user(
            username='transporteur-chauffeur-pays',
            password='secret123',
            telephone='0600000098',
            type_compte='TRANSPORTEUR',
        )
        self.client.force_authenticate(user=transporteur)

        response = self.client.post(
            '/api/chauffeurs/',
            {
                'nom': 'Fatou',
                'telephone': '+2250700000004',
                'numero_permis': 'PERMIS-PAYS-1',
                'pays': 'CI',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['pays'], 'CI')


class ReinitialisationMotDePasseParEmailTests(TestCase):
    """`demander_reinitialisation`/`confirmer_reinitialisation` : le code
    part désormais par email (`envoyer_email_reinitialisation`), jamais dans
    la réponse API — une version antérieure le renvoyait directement ici
    (mode démo, aucune passerelle configurée), ce qui permettait à quiconque
    connaissant un numéro de téléphone de réinitialiser le mot de passe
    associé sans jamais y avoir accès."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='reset-email',
            password='ancien-mdp-123',
            telephone='+22370000099',
            email='proprietaire@example.com',
            type_compte='ENTREPRISE',
        )

    def _code_envoye(self):
        self.assertEqual(len(mail.outbox), 1)
        self.assertEqual(mail.outbox[0].to, ['proprietaire@example.com'])
        self.user.refresh_from_db()
        return self.user.code_reinitialisation

    def test_demander_reinitialisation_envoie_un_email_et_ne_renvoie_pas_le_code(self):
        response = self.client.post(
            '/api/mot-de-passe-oublie/',
            {'telephone': '70000099'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertNotIn('code', response.data)

        code = self._code_envoye()
        self.assertRegex(code, r'^\d{6}$')
        self.assertIn(code, mail.outbox[0].body)

    def test_demander_reinitialisation_sans_email_400(self):
        self.user.email = ''
        self.user.save(update_fields=['email'])

        response = self.client.post(
            '/api/mot-de-passe-oublie/',
            {'telephone': '70000099'},
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(len(mail.outbox), 0)

    def test_demander_reinitialisation_telephone_inconnu_404(self):
        response = self.client.post(
            '/api/mot-de-passe-oublie/',
            {'telephone': '70000098'},
            format='json',
        )

        self.assertEqual(response.status_code, 404)
        self.assertEqual(len(mail.outbox), 0)

    def test_cycle_complet_reinitialisation(self):
        self.client.post(
            '/api/mot-de-passe-oublie/', {'telephone': '70000099'}, format='json',
        )
        code = self._code_envoye()

        response = self.client.post(
            '/api/mot-de-passe-oublie/confirmer/',
            {
                'telephone': '70000099',
                'code': code,
                'nouveau_mot_de_passe': 'nouveau-mdp-456',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('nouveau-mdp-456'))
        self.assertFalse(self.user.code_reinitialisation)

    def test_confirmer_mauvais_code_400(self):
        self.client.post(
            '/api/mot-de-passe-oublie/', {'telephone': '70000099'}, format='json',
        )
        self._code_envoye()

        response = self.client.post(
            '/api/mot-de-passe-oublie/confirmer/',
            {
                'telephone': '70000099',
                'code': '000000',
                'nouveau_mot_de_passe': 'nouveau-mdp-456',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertTrue(self.user.check_password('ancien-mdp-123'))

    def test_confirmer_code_expire_400(self):
        self.client.post(
            '/api/mot-de-passe-oublie/', {'telephone': '70000099'}, format='json',
        )
        code = self._code_envoye()

        self.user.code_reinitialisation_expiration = timezone.now() - timedelta(minutes=1)
        self.user.save(update_fields=['code_reinitialisation_expiration'])

        response = self.client.post(
            '/api/mot-de-passe-oublie/confirmer/',
            {
                'telephone': '70000099',
                'code': code,
                'nouveau_mot_de_passe': 'nouveau-mdp-456',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertTrue(self.user.check_password('ancien-mdp-123'))


class TelephoneValidationTests(TestCase):
    """`core/telephone.py` : validation/normalisation par plan de numérotation
    (2026-09-01), et intégration dans l'inscription/connexion."""

    def setUp(self):
        self.client = APIClient()

    # -- valider_et_normaliser : cas valides --------------------------------

    def test_mali_numero_local_valide(self):
        self.assertEqual(valider_et_normaliser('ML', '70707070'), '+22370707070')
        self.assertEqual(valider_et_normaliser('ML', '60606060'), '+22360606060')

    def test_senegal_numero_valide(self):
        self.assertEqual(valider_et_normaliser('SN', '771234567'), '+221771234567')

    def test_cote_ivoire_numero_10_chiffres(self):
        self.assertEqual(valider_et_normaliser('CI', '0712345678'), '+2250712345678')

    def test_benin_numero_avec_01(self):
        self.assertEqual(valider_et_normaliser('BJ', '0142345678'), '+2290142345678')

    def test_ghana_zero_domestique_retire(self):
        """Le Ghana compose ses numéros avec un zéro domestique à l'usage
        courant : l'algorithme doit l'accepter et le retirer au stockage."""
        self.assertEqual(valider_et_normaliser('GH', '0244123456'), '+233244123456')
        # Fonctionne aussi si l'utilisateur ne tape pas le zéro.
        self.assertEqual(valider_et_normaliser('GH', '244123456'), '+233244123456')

    def test_tolere_numero_deja_compose(self):
        """Un `telephone` déjà préfixé de l'indicatif (composition historique
        côté Flutter) doit rester accepté, pas seulement le numéro local seul."""
        self.assertEqual(valider_et_normaliser('ML', '+22370707070'), '+22370707070')

    # -- valider_et_normaliser : cas invalides ------------------------------

    def test_mali_prefixe_invalide(self):
        with self.assertRaises(TelephoneInvalide):
            valider_et_normaliser('ML', '12345678')

    def test_mali_longueur_invalide(self):
        with self.assertRaises(TelephoneInvalide):
            valider_et_normaliser('ML', '707070')

    def test_pays_inconnu(self):
        with self.assertRaises(TelephoneInvalide):
            valider_et_normaliser('XX', '70707070')

    # -- formater_local ------------------------------------------------------

    def test_formater_local_sans_zero_domestique(self):
        self.assertEqual(formater_local('+22370707070', 'ML'), '70707070')

    def test_formater_local_avec_zero_domestique(self):
        self.assertEqual(formater_local('+233244123456', 'GH'), '0244123456')

    def test_formater_local_numero_non_migre_inchange(self):
        """Un numéro qui ne commence pas encore par son indicatif (donnée pas
        migrée) doit s'afficher tel quel plutôt que planter/tronquer à tort."""
        self.assertEqual(formater_local('70707070', 'ML'), '70707070')

    # -- Intégration inscription ---------------------------------------------

    def test_inscription_telephone_invalide_rejetee(self):
        response = self.client.post(
            '/api/register/',
            {
                'username': '99999999',
                'telephone': '99999999',
                'password': 'secret123',
                'email': 'telephone-invalide@example.com',
                'type_compte': 'TRANSPORTEUR',
                'pays': 'ML',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn('telephone', response.data)

    def test_inscription_stocke_en_e164(self):
        response = self.client.post(
            '/api/register/',
            {
                'username': '70009999',
                'telephone': '70009999',
                'password': 'secret123',
                'email': 'e164@example.com',
                'type_compte': 'TRANSPORTEUR',
                'pays': 'ML',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        user = User.objects.get(telephone='+22370009999')
        self.assertEqual(user.username, '+22370009999')

    # -- Intégration connexion (sans indicatif) -------------------------------

    def test_connexion_avec_numero_local_uniquement(self):
        """Le champ de connexion ne doit pas exiger l'indicatif : on
        s'inscrit avec le numéro composé, puis on se reconnecte avec le
        numéro local seul."""
        inscription = self.client.post(
            '/api/register/',
            {
                'username': '70008888',
                'telephone': '70008888',
                'password': 'secret123',
                'email': 'connexion-locale@example.com',
                'type_compte': 'TRANSPORTEUR',
                'pays': 'ML',
            },
            format='json',
        )
        self.assertEqual(inscription.status_code, 201)

        connexion = self.client.post(
            '/api/login/',
            {'telephone': '70008888', 'password': 'secret123'},
            format='json',
        )

        self.assertEqual(connexion.status_code, 200)
        self.assertEqual(connexion.data['user']['telephone'], '+22370008888')

    def test_connexion_desambiguise_par_mot_de_passe_sur_collision_suffixe(self):
        """Cas limite assumé : deux comptes dans des pays différents peuvent
        coïncidentellement partager le même numéro local. La connexion doit
        retrouver le bon compte grâce au mot de passe plutôt que d'échouer."""
        User.objects.create_user(
            username='+22370001234',
            password='motdepasse-mali',
            telephone='+22370001234',
            type_compte='TRANSPORTEUR',
            pays='ML',
        )
        User.objects.create_user(
            username='+22670001234',
            password='motdepasse-burkina',
            telephone='+22670001234',
            type_compte='TRANSPORTEUR',
            pays='BF',
        )

        connexion = self.client.post(
            '/api/login/',
            {'telephone': '70001234', 'password': 'motdepasse-burkina'},
            format='json',
        )

        self.assertEqual(connexion.status_code, 200)
        self.assertEqual(connexion.data['user']['pays'], 'BF')

    # -- correspond_localement : filtre les faux candidats de suffixe --------

    def test_correspond_localement_rejette_collision_de_suffixe_e164(self):
        """La Guinée (+224) et le Mali (+223) n'ont pas le même nombre de
        chiffres locaux : l'E.164 guinéen "+224671112222" se termine par
        "71112222" (le numéro local malien), pure coïncidence de suffixe.
        `correspond_localement` doit rejeter ce faux candidat."""
        self.assertFalse(
            correspond_localement('+224671112222', 'GN', '71112222')
        )
        self.assertTrue(
            correspond_localement('+22371112222', 'ML', '71112222')
        )

    def test_connexion_filtre_les_faux_candidats_par_suffixe(self):
        """Avant `correspond_localement`, un compte guinéen dont l'E.164 se
        termine par coïncidence sur le numéro local malien saisi restait un
        candidat de connexion : si son mot de passe est réutilisé ailleurs
        (cas courant), il pouvait passer l'authentification à la place du
        compte visé. Le filtre doit l'exclure des candidats en amont, avant
        même la vérification du mot de passe."""
        User.objects.create_user(
            username='+224671112222',
            password='motdepasse-partage',
            telephone='+224671112222',
            type_compte='TRANSPORTEUR',
            pays='GN',
        )
        User.objects.create_user(
            username='+22371112222',
            password='motdepasse-partage',
            telephone='+22371112222',
            type_compte='TRANSPORTEUR',
            pays='ML',
        )

        connexion = self.client.post(
            '/api/login/',
            {'telephone': '71112222', 'password': 'motdepasse-partage'},
            format='json',
        )

        self.assertEqual(connexion.status_code, 200)
        self.assertEqual(connexion.data['user']['pays'], 'ML')
        self.assertEqual(connexion.data['user']['telephone'], '+22371112222')


class DashboardViewTests(TestCase):
    """`/api/dashboard/` selon `type_compte` — avant correctif, la branche
    ADMIN levait une AttributeError (`user.objects` au lieu de
    `User.objects`, `user` étant l'instance authentifiée, pas la classe)."""

    def setUp(self):
        self.client = APIClient()

    def test_admin_ne_plante_pas(self):
        admin = User.objects.create_user(
            username='admin-dashboard',
            password='secret123',
            telephone='0600000090',
            type_compte='ADMIN',
        )
        self.client.force_authenticate(user=admin)

        response = self.client.get('/api/dashboard/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['type'], 'ADMIN')
        self.assertEqual(response.data['utilisateurs'], User.objects.count())

    def test_transporteur_ne_plante_pas(self):
        transporteur = User.objects.create_user(
            username='transporteur-dashboard',
            password='secret123',
            telephone='0600000091',
            type_compte='TRANSPORTEUR',
        )
        self.client.force_authenticate(user=transporteur)

        response = self.client.get('/api/dashboard/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['type'], 'TRANSPORTEUR')

    def test_entreprise_ne_plante_pas(self):
        entreprise = User.objects.create_user(
            username='entreprise-dashboard',
            password='secret123',
            telephone='0600000092',
            type_compte='ENTREPRISE',
        )
        self.client.force_authenticate(user=entreprise)

        response = self.client.get('/api/dashboard/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['type'], 'ENTREPRISE')


class PhoneTrackingTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur',
            password='secret123',
            telephone='0600000001',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client',
            password='secret123',
            telephone='0600000002',
            type_compte='ENTREPRISE',
        )
        self.camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='AB-123-XX',
            capacite=20000,
        )
        self.chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Moussa',
            telephone='0600000003',
            numero_permis='PERMIS-1',
            code_acces='1234',
        )
        self.demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
        )
        self.proposition = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.transporteur,
            prix=150000,
        )
        self.mission = Mission.objects.create(
            demande=self.demande,
            proposition=self.proposition,
            client=self.client_user,
            transporteur=self.transporteur,
            prix_final=150000,
        )
        self.mission_camion = MissionCamion.objects.create(
            mission=self.mission,
            camion=self.camion,
            chauffeur=self.chauffeur,
        )

    def test_phone_tracking_creates_position_and_enables_phone_tracking(self):
        self.client.force_authenticate(user=self.transporteur)

        response = self.client.post(
            '/api/tracking/',
            {
                'mission_camion': self.mission_camion.id,
                'latitude': 12.6392,
                'longitude': -8.0025,
                'source': 'TELEPHONE',
                'telephone_chauffeur': self.chauffeur.telephone,
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(PositionGPS.objects.count(), 1)
        position = PositionGPS.objects.get()
        self.assertEqual(position.source, 'TELEPHONE')
        self.assertEqual(position.telephone_chauffeur, self.chauffeur.telephone)
        self.camion.refresh_from_db()
        self.assertTrue(self.camion.suivi_par_telephone)
        self.assertEqual(self.camion.mode_suivi, 'TELEPHONE')

        # Avant le correctif, la position du chauffeur du mission_camion
        # n'était jamais persistée (écrite sur des champs inexistants de
        # MissionCamion, silencieusement ignorés par .save()).
        self.chauffeur.refresh_from_db()
        self.assertEqual(self.chauffeur.latitude, position.latitude)
        self.assertEqual(self.chauffeur.longitude, position.longitude)
        self.assertIsNotNone(self.chauffeur.position_updated_at)

    def test_position_autre_transporteur_403(self):
        """Avant correctif, n'importe quel compte authentifié pouvait poster
        une position sur le mission_camion d'un autre transporteur."""
        autre_transporteur = User.objects.create_user(
            username='autre-transporteur-tracking',
            password='secret123',
            telephone='0600000004',
            type_compte='TRANSPORTEUR',
        )
        self.client.force_authenticate(user=autre_transporteur)

        response = self.client.post(
            '/api/tracking/',
            {
                'mission_camion': self.mission_camion.id,
                'latitude': 12.6392,
                'longitude': -8.0025,
                'source': 'GPS',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 403)
        self.assertEqual(PositionGPS.objects.count(), 0)

    def test_matching_creates_propositions_for_available_trucks_in_departure_city(self):
        # self.camion (setUp) est un CITERNE à Bamako lui aussi : sans cette
        # ligne, il serait à égalité de score avec matching_truck et le
        # matching redeviendrait ambigu. Il est de toute façon occupé sur
        # self.mission dans ce fixture, donc réellement indisponible ici.
        self.camion.disponible = False
        self.camion.save(update_fields=['disponible'])

        matching_truck = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='AB-999-AA',
            capacite=15000,
            ville='Bamako',
            disponible=True,
        )
        Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='BENNE',
            immatriculation='AB-998-BB',
            capacite=12000,
            ville='Bamako',
            disponible=True,
        )
        Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='AB-997-CC',
            capacite=14000,
            ville='Ségou',
            disponible=True,
        )

        demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            quantite=5000,
            date_chargement='2026-08-09',
            unite='litres',
        )

        proposition = proposer_camions_pour_demande(demande)

        self.assertIsNotNone(proposition)
        self.assertEqual(Proposition.objects.filter(demande=demande).count(), 1)
        self.assertEqual(PropositionCamion.objects.filter(proposition=proposition).count(), 1)
        self.assertEqual(PropositionCamion.objects.get(proposition=proposition).camion, matching_truck)


class HistoriquePositionsTests(TestCase):
    """`GET /api/tracking/<mission_camion_id>/historique/` — alimente le
    bouton "Historique" du suivi GPS transporteur, jusque-là un no-op."""

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-hist',
            password='secret123',
            telephone='0600000060',
            type_compte='TRANSPORTEUR',
        )
        self.autre_transporteur = User.objects.create_user(
            username='autre-transporteur-hist',
            password='secret123',
            telephone='0600000061',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-hist',
            password='secret123',
            telephone='0600000062',
            type_compte='ENTREPRISE',
        )
        self.camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='HIST-001',
            capacite=20000,
        )
        self.chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Moussa',
            telephone='0600000063',
            numero_permis='PERMIS-HIST-1',
        )
        demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
        )
        proposition = Proposition.objects.create(
            demande=demande,
            transporteur=self.transporteur,
            prix=150000,
        )
        self.mission = Mission.objects.create(
            demande=demande,
            proposition=proposition,
            client=self.client_user,
            transporteur=self.transporteur,
            prix_final=150000,
        )
        self.mission_camion = MissionCamion.objects.create(
            mission=self.mission,
            camion=self.camion,
            chauffeur=self.chauffeur,
        )
        self.ancienne = PositionGPS.objects.create(
            mission_camion=self.mission_camion,
            latitude=12.60,
            longitude=-8.00,
            source='GPS',
        )
        self.recente = PositionGPS.objects.create(
            mission_camion=self.mission_camion,
            latitude=12.64,
            longitude=-8.01,
            source='GPS',
        )

    def test_historique_du_plus_recent_au_plus_ancien(self):
        self.client.force_authenticate(user=self.transporteur)

        response = self.client.get(
            f'/api/tracking/{self.mission_camion.id}/historique/'
        )

        self.assertEqual(response.status_code, 200)
        ids = [item['id'] for item in response.data]
        self.assertEqual(ids, [self.recente.id, self.ancienne.id])

    def test_historique_mauvais_transporteur_403(self):
        self.client.force_authenticate(user=self.autre_transporteur)

        response = self.client.get(
            f'/api/tracking/{self.mission_camion.id}/historique/'
        )

        self.assertEqual(response.status_code, 403)

    def test_historique_mission_camion_introuvable_404(self):
        self.client.force_authenticate(user=self.transporteur)

        response = self.client.get('/api/tracking/999999/historique/')

        self.assertEqual(response.status_code, 404)


class ClassifierFraicheurTests(TestCase):

    def test_none_is_inconnue(self):
        self.assertEqual(classifier_fraicheur(None), 'INCONNUE')

    def test_seuils(self):
        maintenant = timezone.now()

        self.assertEqual(
            classifier_fraicheur(maintenant - timedelta(seconds=30)),
            'TRES_FIABLE',
        )
        self.assertEqual(
            classifier_fraicheur(maintenant - timedelta(minutes=5)),
            'FIABLE',
        )
        self.assertEqual(
            classifier_fraicheur(maintenant - timedelta(minutes=20)),
            'A_VERIFIER',
        )
        self.assertEqual(
            classifier_fraicheur(maintenant - timedelta(hours=2)),
            'ANCIENNE',
        )


class DistanceKmTests(TestCase):

    def test_meme_point_distance_nulle(self):
        self.assertAlmostEqual(
            distance_km(12.6392, -8.0029, 12.6392, -8.0029), 0, places=3
        )

    def test_bamako_segou_ordre_de_grandeur(self):
        # Bamako (12.6392, -8.0029) -> Ségou (13.4317, -6.2661) : ~235 km à
        # vol d'oiseau. On vérifie un ordre de grandeur, pas une valeur exacte.
        distance = distance_km(12.6392, -8.0029, 13.4317, -6.2661)
        self.assertTrue(180 < distance < 260, distance)


class ResoudrePositionCamionTests(TestCase):

    def setUp(self):
        self.transporteur = User.objects.create_user(
            username='transporteur-position',
            password='secret123',
            telephone='0600000020',
            type_compte='TRANSPORTEUR',
        )
        self.camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='POS-001',
            capacite=20000,
        )
        self.chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Moussa',
            telephone='0600000021',
            numero_permis='PERMIS-POS-1',
        )

    def test_aucune_donnee_retourne_none(self):
        self.assertIsNone(resoudre_position_camion(self.camion))

    def test_position_statique_du_camion_sans_chauffeur(self):
        self.camion.latitude = 12.6392
        self.camion.longitude = -8.0029
        self.camion.save()

        position = resoudre_position_camion(self.camion)

        self.assertEqual(position['source'], 'INCONNUE')
        self.assertEqual(position['fraicheur'], 'INCONNUE')

    def test_chauffeur_affecte_prime_sur_position_statique(self):
        self.camion.latitude = 12.6392
        self.camion.longitude = -8.0029
        self.camion.save()

        self.chauffeur.latitude = 13.4317
        self.chauffeur.longitude = -6.2661
        self.chauffeur.position_updated_at = timezone.now()
        self.chauffeur.save()

        AffectationChauffeur.objects.create(
            chauffeur=self.chauffeur,
            camion=self.camion,
        )

        position = resoudre_position_camion(self.camion)

        self.assertEqual(position['source'], 'CHAUFFEUR')
        self.assertAlmostEqual(float(position['latitude']), 13.4317)
        self.assertEqual(position['fraicheur'], 'TRES_FIABLE')

    def test_position_propre_du_camion_prime_sur_le_chauffeur(self):
        self.camion.latitude = 12.6392
        self.camion.longitude = -8.0029
        self.camion.position_updated_at = timezone.now()
        self.camion.save()

        self.chauffeur.latitude = 13.4317
        self.chauffeur.longitude = -6.2661
        self.chauffeur.position_updated_at = timezone.now()
        self.chauffeur.save()

        AffectationChauffeur.objects.create(
            chauffeur=self.chauffeur,
            camion=self.camion,
        )

        position = resoudre_position_camion(self.camion)

        self.assertEqual(position['source'], 'CAMION')

    def test_chauffeur_affecte_a_un_autre_camion_est_ignore(self):
        autre_camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='POS-002',
            capacite=18000,
        )

        self.chauffeur.latitude = 13.4317
        self.chauffeur.longitude = -6.2661
        self.chauffeur.position_updated_at = timezone.now()
        self.chauffeur.save()

        AffectationChauffeur.objects.create(
            chauffeur=self.chauffeur,
            camion=autre_camion,
        )

        self.assertIsNone(resoudre_position_camion(self.camion))


class ChauffeurPositionViewTests(TestCase):

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-ping',
            password='secret123',
            telephone='0600000030',
            type_compte='TRANSPORTEUR',
        )
        self.chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Moussa',
            telephone='0600000031',
            numero_permis='PERMIS-PING-1',
            code_acces='1234',
        )

    def test_ping_position_met_a_jour_le_chauffeur(self):
        response = self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/position/',
            {'code_acces': '1234', 'latitude': 12.6392, 'longitude': -8.0029},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.chauffeur.refresh_from_db()
        self.assertEqual(float(self.chauffeur.latitude), 12.6392)
        self.assertEqual(float(self.chauffeur.longitude), -8.0029)
        self.assertIsNotNone(self.chauffeur.position_updated_at)

    def test_chauffeur_introuvable_404(self):
        response = self.client.post(
            '/api/chauffeur/999999/position/',
            {'code_acces': '1234', 'latitude': 12.6392, 'longitude': -8.0029},
            format='json',
        )

        self.assertEqual(response.status_code, 404)

    def test_latitude_manquante_400(self):
        response = self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/position/',
            {'code_acces': '1234', 'longitude': -8.0029},
            format='json',
        )

        self.assertEqual(response.status_code, 400)

    def test_refuse_mauvais_code_acces(self):
        # chauffeur_id est un entier séquentiel devinable : sans revérifier
        # le code d'accès ici, n'importe qui pouvait usurper la position GPS
        # d'un chauffeur sans jamais le connaître.
        response = self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/position/',
            {'code_acces': 'faux-code', 'latitude': 12.6392, 'longitude': -8.0029},
            format='json',
        )

        self.assertEqual(response.status_code, 403)


class ChauffeurPhotoViewTests(TestCase):
    """`ChauffeurPhotoView` — ouverte par `chauffeur_id` sans JWT, protégée
    par le code d'accès rejoué à chaque appel (cf. core/views.py
    `_refuser_si_mauvais_code_acces`)."""

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-photo-ch',
            password='secret123',
            telephone='0600000060',
            type_compte='TRANSPORTEUR',
        )
        self.chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Aminata',
            telephone='0600000061',
            numero_permis='PERMIS-PHOTO-1',
            code_acces='1234',
        )

    def test_modifie_la_photo_avec_le_bon_code(self):
        response = self.client.patch(
            f'/api/chauffeur/{self.chauffeur.id}/photo/',
            {'code_acces': '1234', 'photo': _fichier_image()},
            format='multipart',
        )

        self.assertEqual(response.status_code, 200)
        self.chauffeur.refresh_from_db()
        self.assertTrue(bool(self.chauffeur.photo))

    def test_refuse_mauvais_code_acces(self):
        response = self.client.patch(
            f'/api/chauffeur/{self.chauffeur.id}/photo/',
            {'code_acces': 'faux-code', 'photo': _fichier_image()},
            format='multipart',
        )

        self.assertEqual(response.status_code, 403)
        self.chauffeur.refresh_from_db()
        self.assertFalse(bool(self.chauffeur.photo))


class TerminerMissionTests(TestCase):

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-fin',
            password='secret123',
            telephone='0600000040',
            type_compte='TRANSPORTEUR',
        )
        self.autre_transporteur = User.objects.create_user(
            username='autre-transporteur-fin',
            password='secret123',
            telephone='0600000041',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-fin',
            password='secret123',
            telephone='0600000042',
            type_compte='ENTREPRISE',
        )
        self.camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='FIN-001',
            capacite=20000,
            disponible=False,
        )
        self.chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Moussa',
            telephone='0600000043',
            numero_permis='PERMIS-FIN-1',
            disponible=False,
        )
        AffectationChauffeur.objects.create(
            chauffeur=self.chauffeur,
            camion=self.camion,
        )
        self.demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
            statut='EN_COURS',
        )
        proposition = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.transporteur,
            prix=150000,
        )
        self.mission = Mission.objects.create(
            demande=self.demande,
            proposition=proposition,
            client=self.client_user,
            transporteur=self.transporteur,
            prix_final=150000,
        )
        MissionCamion.objects.create(
            mission=self.mission,
            camion=self.camion,
            chauffeur=self.chauffeur,
        )

    def test_termine_libere_camion_et_chauffeur_sans_toucher_affectation(self):
        self.client.force_authenticate(user=self.transporteur)

        response = self.client.post(f'/api/missions/{self.mission.id}/terminer/')

        self.assertEqual(response.status_code, 200)

        self.mission.refresh_from_db()
        self.camion.refresh_from_db()
        self.chauffeur.refresh_from_db()

        self.assertEqual(self.mission.statut, 'TERMINEE')
        self.assertIsNotNone(self.mission.date_arrivee)
        self.assertTrue(self.camion.disponible)
        self.assertTrue(self.chauffeur.disponible)
        self.assertIsNotNone(self.camion.affectation_active)
        self.assertEqual(self.camion.affectation_active.chauffeur, self.chauffeur)
        self.assertTrue(
            Notification.objects.filter(
                destinataire=self.client_user,
                type_notification=Notification.Type.MISSION_TERMINEE,
            ).exists()
        )
        # Avant correctif, `DemandeTransport.statut` ne bougeait jamais de
        # OUVERTE : une demande dont la mission était déjà terminée
        # continuait d'apparaître comme "à proposer" côté transporteur.
        self.demande.refresh_from_db()
        self.assertEqual(self.demande.statut, 'TERMINEE')

    def test_mauvais_transporteur_403(self):
        self.client.force_authenticate(user=self.autre_transporteur)

        response = self.client.post(f'/api/missions/{self.mission.id}/terminer/')

        self.assertEqual(response.status_code, 403)
        self.mission.refresh_from_db()
        self.assertNotEqual(self.mission.statut, 'TERMINEE')


class AccepterRefuserMissionTests(TestCase):
    """`accepter_mission` (démarrage PLANIFIEE -> EN_COURS) et
    `refuser_mission` (annulation -> ANNULEE). Avant correctif, la première
    plantait (`mission.camion` n'existe pas) et la seconde écrivait un
    statut hors de `Mission.Statut` sans jamais rien libérer."""

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-accref',
            password='secret123',
            telephone='0600000050',
            type_compte='TRANSPORTEUR',
        )
        self.autre_transporteur = User.objects.create_user(
            username='autre-transporteur-accref',
            password='secret123',
            telephone='0600000051',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-accref',
            password='secret123',
            telephone='0600000052',
            type_compte='ENTREPRISE',
        )
        self.camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='ACC-001',
            capacite=20000,
            disponible=True,
        )
        self.chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Moussa',
            telephone='0600000053',
            numero_permis='PERMIS-ACC-1',
            disponible=True,
        )
        AffectationChauffeur.objects.create(
            chauffeur=self.chauffeur,
            camion=self.camion,
        )
        self.demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
            statut='EN_COURS',
        )
        proposition = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.transporteur,
            prix=150000,
        )
        self.mission = Mission.objects.create(
            demande=self.demande,
            proposition=proposition,
            client=self.client_user,
            transporteur=self.transporteur,
            prix_final=150000,
        )
        MissionCamion.objects.create(
            mission=self.mission,
            camion=self.camion,
            chauffeur=self.chauffeur,
        )

    def test_accepter_demarre_et_bloque_camion_et_chauffeur(self):
        self.client.force_authenticate(user=self.transporteur)

        response = self.client.post(f'/api/missions/{self.mission.id}/accepter/')

        self.assertEqual(response.status_code, 200)

        self.mission.refresh_from_db()
        self.camion.refresh_from_db()
        self.chauffeur.refresh_from_db()

        self.assertEqual(self.mission.statut, 'EN_COURS')
        self.assertIsNotNone(self.mission.date_depart)
        self.assertFalse(self.camion.disponible)
        self.assertFalse(self.chauffeur.disponible)
        self.assertTrue(
            Notification.objects.filter(
                destinataire=self.client_user,
                type_notification=Notification.Type.MISSION_DEMARREE,
            ).exists()
        )

    def test_accepter_mauvais_transporteur_403(self):
        self.client.force_authenticate(user=self.autre_transporteur)

        response = self.client.post(f'/api/missions/{self.mission.id}/accepter/')

        self.assertEqual(response.status_code, 403)

    def test_accepter_deux_fois_400(self):
        self.client.force_authenticate(user=self.transporteur)

        self.client.post(f'/api/missions/{self.mission.id}/accepter/')
        response = self.client.post(f'/api/missions/{self.mission.id}/accepter/')

        self.assertEqual(response.status_code, 400)

    def test_refuser_annule_et_libere_camion_et_chauffeur(self):
        self.client.force_authenticate(user=self.transporteur)

        # La mission a déjà démarré : camion/chauffeur sont bloqués.
        self.client.post(f'/api/missions/{self.mission.id}/accepter/')

        response = self.client.post(f'/api/missions/{self.mission.id}/refuser/')

        self.assertEqual(response.status_code, 200)

        self.mission.refresh_from_db()
        self.camion.refresh_from_db()
        self.chauffeur.refresh_from_db()

        self.assertEqual(self.mission.statut, 'ANNULEE')
        self.assertTrue(self.camion.disponible)
        self.assertTrue(self.chauffeur.disponible)
        # Avant correctif, aucune notification n'était envoyée à l'annulation
        # (contrairement à accepter_mission/terminer_mission) : le client
        # n'avait aucun moyen de savoir que sa mission avait été annulée.
        self.assertTrue(
            Notification.objects.filter(
                destinataire=self.client_user,
                type_notification=Notification.Type.MISSION_ANNULEE,
            ).exists()
        )
        # Le besoin de transport de l'entreprise n'a pas disparu : la
        # demande doit redevenir visible ("OUVERTE") pour d'autres
        # transporteurs, pas rester coincée en EN_COURS pour toujours.
        self.demande.refresh_from_db()
        self.assertEqual(self.demande.statut, 'OUVERTE')

    def test_refuser_mauvais_transporteur_403(self):
        self.client.force_authenticate(user=self.autre_transporteur)

        response = self.client.post(f'/api/missions/{self.mission.id}/refuser/')

        self.assertEqual(response.status_code, 403)


class DashboardTransporteurCompteursTests(TestCase):
    """`missions_en_attente` filtrait sur un statut ('EN_ATTENTE') absent de
    `Mission.Statut` : toujours 0, quel que soit le nombre de missions
    planifiées. Corrigé pour filtrer sur `Mission.Statut.PLANIFIEE`."""

    def test_missions_en_attente_compte_les_planifiees(self):
        transporteur = User.objects.create_user(
            username='transporteur-compteurs',
            password='secret123',
            telephone='0600000060',
            type_compte='TRANSPORTEUR',
        )
        client_user = User.objects.create_user(
            username='client-compteurs',
            password='secret123',
            telephone='0600000061',
            type_compte='ENTREPRISE',
        )
        demande = DemandeTransport.objects.create(
            client=client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
        )
        proposition = Proposition.objects.create(
            demande=demande,
            transporteur=transporteur,
            prix=150000,
        )
        Mission.objects.create(
            demande=demande,
            proposition=proposition,
            client=client_user,
            transporteur=transporteur,
            prix_final=150000,
            statut='PLANIFIEE',
        )

        client = APIClient()
        client.force_authenticate(user=transporteur)

        response = client.get('/api/dashboard/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['missions_en_attente'], 1)


class ProposerCamionsPourDemandeCountryScoringTests(TestCase):
    """`proposer_camions_pour_demande` scorait uniquement sur la ville, sans
    notion de pays : deux camions dans une ville du même nom mais de pays
    différents obtenaient exactement le même score. Régression : à ville
    identique, le camion du bon pays doit l'emporter."""

    def setUp(self):
        self.transporteur = User.objects.create_user(
            username='transporteur-scoring-pays',
            password='secret123',
            telephone='0600000060',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-scoring-pays',
            password='secret123',
            telephone='0600000061',
            type_compte='ENTREPRISE',
        )

        # Même nom de ville des deux côtés de la frontière, pour isoler le
        # signal "pays" du signal "ville" (déjà couvert ailleurs).
        self.camion_bon_pays = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='PAYS-BON',
            capacite=20000,
            disponible=True,
            ville='Frontville',
            pays='ML',
        )
        self.camion_mauvais_pays = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='PAYS-MAUVAIS',
            capacite=20000,
            disponible=True,
            ville='Frontville',
            pays='SN',
        )

    def test_camion_du_bon_pays_gagne_a_ville_identique(self):
        demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Frontville',
            ville_arrivee='Ailleurs',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
            pays_depart='ML',
            pays_arrivee='SN',
        )

        proposition = proposer_camions_pour_demande(demande)

        self.assertIsNotNone(proposition)
        camion_propose = proposition.camions.get().camion
        self.assertEqual(camion_propose, self.camion_bon_pays)


class ProposerCamionsPourDemandeFormatScoringTests(TestCase):
    """Le bonus `format_camion` (2026-08-27) est un score, pas un filtre dur
    : à ville/pays identiques, un camion au bon format doit l'emporter, mais
    un camion du bon type sans le bon format reste quand même proposé si
    c'est le seul candidat (voir test dédié plus bas)."""

    def setUp(self):
        self.transporteur = User.objects.create_user(
            username='transporteur-scoring-format',
            password='secret123',
            telephone='0600000070',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-scoring-format',
            password='secret123',
            telephone='0600000071',
            type_compte='ENTREPRISE',
        )
        self.camion_bon_format = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='PLATEAU',
            format_camion='40_PIEDS',
            immatriculation='FORMAT-BON',
            capacite=20000,
            disponible=True,
            ville='Bamako',
        )
        self.camion_autre_format = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='PLATEAU',
            format_camion='20_PIEDS',
            immatriculation='FORMAT-AUTRE',
            capacite=20000,
            disponible=True,
            ville='Bamako',
        )

    def test_camion_du_bon_format_gagne(self):
        demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='PLATEAU',
            format_camion='40_PIEDS',
            ville_depart='Bamako',
            ville_arrivee='Kayes',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='tonnes',
        )

        proposition = proposer_camions_pour_demande(demande)

        self.assertIsNotNone(proposition)
        camion_propose = proposition.camions.get().camion
        self.assertEqual(camion_propose, self.camion_bon_format)

    def test_sans_format_demande_ne_filtre_pas(self):
        # `format_camion` vide sur la demande : le bonus ne s'applique pas,
        # mais le matching type-seul continue de fonctionner normalement.
        demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='PLATEAU',
            ville_depart='Bamako',
            ville_arrivee='Kayes',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='tonnes',
        )

        proposition = proposer_camions_pour_demande(demande)

        self.assertIsNotNone(proposition)


class RechercheCamionViewTests(TestCase):

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-recherche',
            password='secret123',
            telephone='0600000050',
            type_compte='TRANSPORTEUR',
        )
        self.client.force_authenticate(user=self.transporteur)

        # Bamako, référence de recherche.
        self.reference = (12.6392, -8.0029)

        # Camion A : un peu plus loin (~5 km) mais position très fraîche.
        self.camion_proche_frais = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='REC-A',
            capacite=20000,
            disponible=True,
            latitude=12.68,
            longitude=-8.0029,
            position_updated_at=timezone.now(),
        )

        # Camion B : plus proche (~3 km) mais position vieille de 2h.
        self.camion_proche_vieux = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='REC-B',
            capacite=20000,
            disponible=True,
            latitude=12.665,
            longitude=-8.0029,
            position_updated_at=timezone.now() - timedelta(hours=2),
        )

        # Camion C : disponible mais aucune position connue.
        self.camion_sans_position = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='REC-C',
            capacite=20000,
            disponible=True,
        )

        # Camion D : capacité trop faible, doit être exclu par capacite_min.
        Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='REC-D',
            capacite=5000,
            disponible=True,
            latitude=12.6392,
            longitude=-8.0029,
            position_updated_at=timezone.now(),
        )

    def test_camion_proche_frais_devant_camion_proche_mais_vieux(self):
        response = self.client.get(
            '/api/recherche-camions/',
            {
                'type_camion': 'CITERNE',
                'latitude': self.reference[0],
                'longitude': self.reference[1],
            },
        )

        self.assertEqual(response.status_code, 200)

        immatriculations = [item['immatriculation'] for item in response.data]

        self.assertLess(
            immatriculations.index('REC-A'),
            immatriculations.index('REC-B'),
        )
        # Le camion sans position connue doit être renvoyé, mais en dernier.
        self.assertEqual(immatriculations[-1], 'REC-C')

        camion_a = next(item for item in response.data if item['immatriculation'] == 'REC-A')
        self.assertEqual(camion_a['position']['source'], 'CAMION')
        self.assertIsNotNone(camion_a['distance_km'])

    def test_capacite_min_filtre_les_camions_trop_petits(self):
        response = self.client.get(
            '/api/recherche-camions/',
            {'type_camion': 'CITERNE', 'capacite_min': 10000},
        )

        immatriculations = [item['immatriculation'] for item in response.data]

        self.assertNotIn('REC-D', immatriculations)
        self.assertIn('REC-A', immatriculations)

    def test_filtre_par_pays(self):
        self.camion_proche_frais.pays = 'SN'
        self.camion_proche_frais.save(update_fields=['pays'])

        response = self.client.get(
            '/api/recherche-camions/',
            {'type_camion': 'CITERNE', 'pays': 'SN'},
        )

        immatriculations = [item['immatriculation'] for item in response.data]

        self.assertEqual(immatriculations, ['REC-A'])


class FlottePositionsViewTests(TestCase):
    """`/api/transporteur/flotte-positions/` — la vue "où sont mes
    camions/chauffeurs" du transporteur. Contrairement à RechercheCamionView
    (marché, camions disponibles uniquement), elle doit montrer TOUS les
    camions du transporteur, y compris ceux en mission (disponible=False),
    avec le chauffeur affecté."""

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-flotte',
            password='secret123',
            telephone='0600000110',
            type_compte='TRANSPORTEUR',
        )
        self.autre_transporteur = User.objects.create_user(
            username='autre-transporteur-flotte',
            password='secret123',
            telephone='0600000111',
            type_compte='TRANSPORTEUR',
        )
        self.client.force_authenticate(user=self.transporteur)

        self.chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Oumar',
            telephone='0600000112',
            numero_permis='PERMIS-FLOTTE-1',
            latitude=12.65,
            longitude=-8.01,
            position_updated_at=timezone.now(),
        )

        # Camion AVEC chauffeur affecté et position résolue via le
        # téléphone du chauffeur (pas de position GPS propre au camion).
        self.camion_avec_chauffeur = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='FLOTTE-A',
            capacite=20000,
            disponible=False,  # en mission : doit quand même apparaître
        )
        AffectationChauffeur.objects.create(
            chauffeur=self.chauffeur,
            camion=self.camion_avec_chauffeur,
        )

        # Camion SANS chauffeur ni position connue.
        self.camion_sans_chauffeur = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='BENNE',
            immatriculation='FLOTTE-B',
            capacite=15000,
        )

        # Camion d'un AUTRE transporteur : ne doit jamais apparaître.
        Camion.objects.create(
            proprietaire=self.autre_transporteur,
            type_camion='CITERNE',
            immatriculation='FLOTTE-AUTRE',
            capacite=20000,
        )

    def test_montre_tous_les_camions_du_transporteur_y_compris_en_mission(self):
        response = self.client.get('/api/transporteur/flotte-positions/')

        self.assertEqual(response.status_code, 200)
        immatriculations = {item['immatriculation'] for item in response.data}
        self.assertEqual(immatriculations, {'FLOTTE-A', 'FLOTTE-B'})

    def test_expose_le_chauffeur_affecte_et_sa_position(self):
        response = self.client.get('/api/transporteur/flotte-positions/')

        camion_a = next(
            item for item in response.data
            if item['immatriculation'] == 'FLOTTE-A'
        )
        self.assertEqual(camion_a['chauffeur_actuel']['nom'], 'Oumar')
        self.assertEqual(camion_a['position']['source'], 'CHAUFFEUR')
        self.assertEqual(camion_a['position']['fraicheur'], 'TRES_FIABLE')

        camion_b = next(
            item for item in response.data
            if item['immatriculation'] == 'FLOTTE-B'
        )
        self.assertIsNone(camion_b['chauffeur_actuel'])
        self.assertIsNone(camion_b['position'])


class ImageCamionTests(TestCase):
    """Gestion des photos existantes : la première uploadée devient
    automatiquement principale, `ImageCamionDetailView` permet de changer
    laquelle est principale ou de supprimer une photo, et tout est isolé
    par transporteur."""

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-images',
            password='secret123',
            telephone='0600000070',
            type_compte='TRANSPORTEUR',
        )
        self.autre_transporteur = User.objects.create_user(
            username='autre-transporteur-images',
            password='secret123',
            telephone='0600000071',
            type_compte='TRANSPORTEUR',
        )
        self.camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='IMG-001',
            capacite=20000,
        )
        self.client.force_authenticate(user=self.transporteur)

    def test_premiere_image_devient_principale_automatiquement(self):
        response = self.client.post(
            '/api/camions/images/',
            {'camion': self.camion.id, 'image': _fichier_image()},
            format='multipart',
        )

        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data['principale'])

    def test_definir_une_nouvelle_principale_desactive_les_autres(self):
        premiere = ImageCamion.objects.create(
            camion=self.camion, image=_fichier_image('a.png'), principale=True
        )
        deuxieme = ImageCamion.objects.create(
            camion=self.camion, image=_fichier_image('b.png'), principale=False
        )

        response = self.client.patch(
            f'/api/camions/images/{deuxieme.id}/',
            {'principale': True},
            format='json',
        )

        self.assertEqual(response.status_code, 200)

        premiere.refresh_from_db()
        deuxieme.refresh_from_db()
        self.assertFalse(premiere.principale)
        self.assertTrue(deuxieme.principale)

    def test_suppression_image(self):
        image = ImageCamion.objects.create(
            camion=self.camion, image=_fichier_image(), principale=True
        )

        response = self.client.delete(f'/api/camions/images/{image.id}/')

        self.assertEqual(response.status_code, 204)
        self.assertFalse(ImageCamion.objects.filter(id=image.id).exists())

    def test_changer_la_principale_fonctionne_meme_a_4_images(self):
        """Régression : `ImageCamion.save()` vérifiait `count() >= 4` sur
        CHAQUE sauvegarde, y compris la mise à jour d'une image déjà
        existante — un camion déjà à 4/4 photos ne pouvait plus jamais
        changer laquelle est principale, PATCH plantait en 500 (l'update
        était vue à tort comme un 5e ajout). Le check ne doit s'appliquer
        qu'à la création (`self.pk is None`)."""
        images = [
            ImageCamion.objects.create(
                camion=self.camion,
                image=_fichier_image(f'img{i}.png'),
                principale=(i == 0),
            )
            for i in range(4)
        ]

        response = self.client.patch(
            f'/api/camions/images/{images[3].id}/',
            {'principale': True},
            format='json',
        )

        self.assertEqual(response.status_code, 200)

        images[0].refresh_from_db()
        images[3].refresh_from_db()
        self.assertFalse(images[0].principale)
        self.assertTrue(images[3].principale)

    def test_creation_d_une_5e_image_toujours_refusee(self):
        """Le garde-fou `self.pk is None` ne doit assouplir la limite que
        pour les mises à jour, pas pour la création : un camion déjà à 4/4
        doit toujours refuser une 5e photo."""
        for i in range(4):
            ImageCamion.objects.create(
                camion=self.camion, image=_fichier_image(f'existante{i}.png')
            )

        response = self.client.post(
            '/api/camions/images/',
            {'camion': self.camion.id, 'image': _fichier_image('5e.png')},
            format='multipart',
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            ImageCamion.objects.filter(camion=self.camion).count(), 4
        )

    def test_isolation_par_transporteur(self):
        image = ImageCamion.objects.create(
            camion=self.camion, image=_fichier_image(), principale=True
        )

        self.client.force_authenticate(user=self.autre_transporteur)

        response_patch = self.client.patch(
            f'/api/camions/images/{image.id}/',
            {'principale': False},
            format='json',
        )
        response_delete = self.client.delete(f'/api/camions/images/{image.id}/')

        self.assertEqual(response_patch.status_code, 404)
        self.assertEqual(response_delete.status_code, 404)
        self.assertTrue(ImageCamion.objects.filter(id=image.id).exists())


class AdminDashboardViewTests(TestCase):

    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            username='admin-dashboard-2',
            password='secret123',
            telephone='0600000080',
            type_compte='ADMIN',
        )
        self.transporteur = User.objects.create_user(
            username='transporteur-admin-dash',
            password='secret123',
            telephone='0600000081',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-admin-dash',
            password='secret123',
            telephone='0600000082',
            type_compte='ENTREPRISE',
        )
        self.camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='ADM-001',
            capacite=20000,
            disponible=True,
        )
        Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Moussa',
            telephone='0600000083',
            numero_permis='PERMIS-ADM-1',
        )
        demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Kayes',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
            statut='OUVERTE',
        )
        proposition = Proposition.objects.create(
            demande=demande,
            transporteur=self.transporteur,
            prix=150000,
        )
        Mission.objects.create(
            demande=demande,
            proposition=proposition,
            client=self.client_user,
            transporteur=self.transporteur,
            prix_final=150000,
            statut='TERMINEE',
        )

    def test_admin_voit_les_statistiques_globales(self):
        self.client.force_authenticate(user=self.admin)

        response = self.client.get('/api/admin/dashboard/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['transporteurs_total'], 1)
        self.assertEqual(response.data['entreprises_total'], 1)
        self.assertEqual(response.data['chauffeurs_total'], 1)
        self.assertEqual(response.data['camions_total'], 1)
        self.assertEqual(response.data['camions_disponibles'], 1)
        self.assertEqual(response.data['missions_total'], 1)
        self.assertEqual(response.data['missions_terminees'], 1)
        self.assertEqual(response.data['demandes_ouvertes'], 1)
        self.assertEqual(
            response.data['revenus_total'],
            [{'devise': 'XOF', 'montant': 150000.0}],
        )

    def test_transporteur_refuse_403(self):
        self.client.force_authenticate(user=self.transporteur)

        response = self.client.get('/api/admin/dashboard/')

        self.assertEqual(response.status_code, 403)


class RevenusParDeviseTests(TestCase):
    """Le passage au périmètre CEDEAO a rendu `Mission.prix_final`
    multi-devises (dérivée de `demande.pays_depart`, jamais stockée) : un
    simple Sum() SQL mélangerait XOF, GHS, NGN... `revenus_par_devise`
    (services.py) ventile donc par devise plutôt que de renvoyer un total
    unique, pour TransporteurDashboardView, AdminDashboardView et
    ClientDashboardView."""

    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            username='admin-revenus-devise',
            password='secret123',
            telephone='0600000200',
            type_compte='ADMIN',
        )
        self.transporteur = User.objects.create_user(
            username='transporteur-revenus-devise',
            password='secret123',
            telephone='0600000201',
            type_compte='TRANSPORTEUR',
        )
        self.autre_transporteur = User.objects.create_user(
            username='autre-transporteur-revenus-devise',
            password='secret123',
            telephone='0600000202',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-revenus-devise',
            password='secret123',
            telephone='0600000203',
            type_compte='ENTREPRISE',
        )

    def _creer_mission(self, transporteur, pays_depart, prix, statut='TERMINEE'):
        demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Ville A',
            ville_arrivee='Ville B',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
            pays_depart=pays_depart,
            pays_arrivee=pays_depart,
        )
        proposition = Proposition.objects.create(
            demande=demande,
            transporteur=transporteur,
            prix=prix,
        )
        return Mission.objects.create(
            demande=demande,
            proposition=proposition,
            client=self.client_user,
            transporteur=transporteur,
            prix_final=prix,
            statut=statut,
        )

    def test_transporteur_dashboard_ventile_les_revenus_par_devise(self):
        # ML et SN partagent le XOF : ces deux missions doivent se combiner
        # en une seule entrée plutôt que rester séparées par pays.
        self._creer_mission(self.transporteur, 'ML', 100000)
        self._creer_mission(self.transporteur, 'SN', 50000)
        self._creer_mission(self.transporteur, 'GH', 80000)
        # Pas TERMINEE : ne doit pas entrer dans la ventilation.
        self._creer_mission(self.transporteur, 'NG', 999999, statut='EN_COURS')

        self.client.force_authenticate(user=self.transporteur)
        response = self.client.get('/api/transporteur/dashboard/')

        self.assertEqual(response.status_code, 200)

        revenus = {
            entree['devise']: entree['montant']
            for entree in response.data['revenus']
        }
        self.assertEqual(revenus, {'XOF': 150000.0, 'GHS': 80000.0})
        # Devise dominante en tête (tri par montant décroissant).
        self.assertEqual(response.data['revenus'][0]['devise'], 'XOF')
        # Toutes les missions datent d'aujourd'hui : même ventilation sur
        # les trois fenêtres temporelles (total / mois / année).
        self.assertEqual(response.data['revenus_mois'], response.data['revenus'])
        self.assertEqual(response.data['revenus_annee'], response.data['revenus'])

    def test_transporteur_dashboard_isole_les_revenus_dun_autre_transporteur(self):
        self._creer_mission(self.transporteur, 'ML', 100000)
        self._creer_mission(self.autre_transporteur, 'GH', 999999)

        self.client.force_authenticate(user=self.transporteur)
        response = self.client.get('/api/transporteur/dashboard/')

        self.assertEqual(
            response.data['revenus'],
            [{'devise': 'XOF', 'montant': 100000.0}],
        )

    def test_transporteur_dashboard_sans_mission_terminee_renvoie_liste_vide(self):
        self.client.force_authenticate(user=self.transporteur)
        response = self.client.get('/api/transporteur/dashboard/')

        self.assertEqual(response.data['revenus'], [])
        self.assertEqual(response.data['revenus_mois'], [])
        self.assertEqual(response.data['revenus_annee'], [])

    def test_admin_dashboard_ventile_les_revenus_de_toute_la_plateforme(self):
        self._creer_mission(self.transporteur, 'ML', 100000)
        self._creer_mission(self.autre_transporteur, 'GH', 80000)
        self._creer_mission(self.autre_transporteur, 'NG', 30000)

        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/admin/dashboard/')

        self.assertEqual(response.status_code, 200)

        revenus = {
            entree['devise']: entree['montant']
            for entree in response.data['revenus_total']
        }
        self.assertEqual(
            revenus,
            {'XOF': 100000.0, 'GHS': 80000.0, 'NGN': 30000.0},
        )

    def test_client_dashboard_ventile_les_depenses_par_devise(self):
        # Toutes ces missions appartiennent à self.client_user (cf.
        # _creer_mission) : un client qui commande dans plusieurs pays
        # CEDEAO doit voir ses dépenses ventilées par devise, pas mélangées.
        self._creer_mission(self.transporteur, 'ML', 100000)
        self._creer_mission(self.autre_transporteur, 'GH', 80000)
        self._creer_mission(self.autre_transporteur, 'NG', 30000)
        # Pas TERMINEE : ne doit pas entrer dans la ventilation.
        self._creer_mission(self.transporteur, 'SN', 999999, statut='EN_COURS')

        self.client.force_authenticate(user=self.client_user)
        response = self.client.get('/api/client/dashboard/')

        self.assertEqual(response.status_code, 200)

        depenses = {
            entree['devise']: entree['montant']
            for entree in response.data['depenses_total']
        }
        self.assertEqual(
            depenses,
            {'XOF': 100000.0, 'GHS': 80000.0, 'NGN': 30000.0},
        )
        # Toutes les missions datent d'aujourd'hui : même ventilation sur
        # les deux fenêtres temporelles (total / mois).
        self.assertEqual(response.data['depenses_mois'], response.data['depenses_total'])


class ClientDashboardViewTests(TestCase):
    """`/api/client/dashboard/` — pendant client de `TransporteurDashboardView`,
    aucune source de stats n'existait avant pour `DashboardClient` côté Flutter."""

    def setUp(self):
        self.client = APIClient()
        self.client_user = User.objects.create_user(
            username='client-dashboard',
            password='secret123',
            telephone='0600000095',
            type_compte='ENTREPRISE',
        )
        self.transporteur = User.objects.create_user(
            username='transporteur-client-dash',
            password='secret123',
            telephone='0600000096',
            type_compte='TRANSPORTEUR',
        )

        DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Kayes',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
            statut='OUVERTE',
        )
        demande_terminee = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Sikasso',
            quantite=3000,
            date_chargement='2026-08-08',
            unite='litres',
            statut='TERMINEE',
        )
        proposition = Proposition.objects.create(
            demande=demande_terminee,
            transporteur=self.transporteur,
            prix=200000,
        )
        Mission.objects.create(
            demande=demande_terminee,
            proposition=proposition,
            client=self.client_user,
            transporteur=self.transporteur,
            prix_final=200000,
            statut='TERMINEE',
        )

        # Une demande d'un AUTRE client ne doit jamais apparaître ici.
        autre_client = User.objects.create_user(
            username='autre-client-dash',
            password='secret123',
            telephone='0600000097',
            type_compte='ENTREPRISE',
        )
        DemandeTransport.objects.create(
            client=autre_client,
            type_camion='CITERNE',
            ville_depart='Dakar',
            ville_arrivee='Thiès',
            quantite=1000,
            date_chargement='2026-08-08',
            unite='litres',
            statut='OUVERTE',
        )

    def test_client_voit_uniquement_ses_propres_statistiques(self):
        self.client.force_authenticate(user=self.client_user)

        response = self.client.get('/api/client/dashboard/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['demandes_total'], 2)
        self.assertEqual(response.data['demandes_ouvertes'], 1)
        self.assertEqual(response.data['demandes_terminees'], 1)
        self.assertEqual(response.data['missions_total'], 1)
        self.assertEqual(response.data['missions_terminees'], 1)
        # `demande_terminee` n'a pas de pays_depart explicite -> défaut "ML"
        # -> XOF (cf. devise_pour_pays). Ventilé par devise comme
        # TransporteurDashboardView/AdminDashboardView, cf. RevenusParDeviseTests.
        self.assertEqual(
            response.data['depenses_total'],
            [{'devise': 'XOF', 'montant': 200000.0}],
        )


class NotificationTests(TestCase):

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-notif',
            password='secret123',
            telephone='0600000090',
            type_compte='TRANSPORTEUR',
        )
        self.autre_transporteur = User.objects.create_user(
            username='autre-transporteur-notif',
            password='secret123',
            telephone='0600000091',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-notif',
            password='secret123',
            telephone='0600000092',
            type_compte='ENTREPRISE',
        )
        self.camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='NOTIF-001',
            capacite=20000,
            disponible=True,
            ville='Bamako',
        )
        self.demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
        )

    def test_matching_automatique_notifie_le_transporteur(self):
        proposition = proposer_camions_pour_demande(self.demande)

        notif = Notification.objects.get(
            destinataire=self.transporteur,
            type_notification=Notification.Type.NOUVELLE_DEMANDE,
        )
        # Lien vivant vers la proposition auto-créée : sans lui, tapoter
        # cette notification côté transporteur ne pouvait mener nulle part.
        self.assertEqual(notif.proposition_id, proposition.id)

    def test_matching_automatique_notifie_aussi_le_client(self):
        # Sans ce notifier (ajouté 2026-08-21), l'entreprise n'apprenait
        # jamais qu'une proposition existait déjà pour sa demande — seul le
        # transporteur était notifié : l'icône de notif ne s'allumait jamais
        # côté client pour une proposition issue du matching automatique.
        proposition = proposer_camions_pour_demande(self.demande)
        self.assertIsNotNone(proposition)

        notif = Notification.objects.get(
            destinataire=self.client_user,
            type_notification=Notification.Type.NOUVELLE_PROPOSITION,
        )
        self.assertEqual(notif.proposition_id, proposition.id)

    def test_matching_automatique_previent_aussi_les_autres_transporteurs_eligibles(self):
        # Un seul camion (le mieux noté) reçoit la proposition automatique,
        # mais tout transporteur ayant un camion disponible du bon type doit
        # être prévenu — sinon sa seule chance de découvrir la demande est de
        # tomber dessus par hasard dans "Demandes disponibles", où elle est
        # pourtant visible dès sa création (DemandeTransportListCreateView).
        Camion.objects.create(
            proprietaire=self.autre_transporteur,
            type_camion='CITERNE',
            immatriculation='NOTIF-002',
            capacite=15000,
            disponible=True,
            ville='Ouagadougou',  # ne matche ni ville_depart ni ville_arrivee
        )

        proposition = proposer_camions_pour_demande(self.demande)

        self.assertEqual(Proposition.objects.filter(demande=self.demande).count(), 1)

        notif_gagnant = Notification.objects.get(
            destinataire=self.transporteur,
            type_notification=Notification.Type.NOUVELLE_DEMANDE,
        )
        self.assertEqual(notif_gagnant.proposition_id, proposition.id)

        notif_autre = Notification.objects.get(
            destinataire=self.autre_transporteur,
            type_notification=Notification.Type.NOUVELLE_DEMANDE,
        )
        self.assertIsNone(notif_autre.proposition_id)

    def test_matching_automatique_reactive_un_camion_libre_ayant_deja_une_historique(self):
        self.camion.disponible = False
        self.camion.save(update_fields=['disponible'])

        ancien_transporteur = User.objects.create_user(
            username='transporteur-historique',
            password='secret123',
            telephone='0600000093',
            type_compte='TRANSPORTEUR',
        )
        camion_historique = Camion.objects.create(
            proprietaire=ancien_transporteur,
            type_camion='CITERNE',
            immatriculation='HIST-001',
            capacite=20000,
            disponible=True,
            ville='Bamako',
        )
        ancienne_demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            quantite=5000,
            date_chargement='2026-08-05',
            unite='litres',
            statut='TERMINEE',
        )
        ancienne_proposition = Proposition.objects.create(
            demande=ancienne_demande,
            transporteur=ancien_transporteur,
            prix=180000,
            statut='ACCEPTEE',
        )
        ancienne_mission = Mission.objects.create(
            demande=ancienne_demande,
            proposition=ancienne_proposition,
            client=self.client_user,
            transporteur=ancien_transporteur,
            prix_final=180000,
            statut=Mission.Statut.TERMINEE,
        )
        MissionCamion.objects.create(
            mission=ancienne_mission,
            camion=camion_historique,
            ordre=1,
        )

        nouvelle_demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            quantite=6000,
            date_chargement='2026-08-10',
            unite='litres',
            statut='OUVERTE',
        )

        proposition = proposer_camions_pour_demande(nouvelle_demande)

        self.assertIsNotNone(proposition)
        self.assertEqual(proposition.transporteur, ancien_transporteur)
        self.assertEqual(
            Notification.objects.filter(
                destinataire=ancien_transporteur,
                type_notification=Notification.Type.NOUVELLE_DEMANDE,
            ).count(),
            1,
        )

    def test_creation_proposition_notifie_le_client(self):
        self.client.force_authenticate(user=self.transporteur)

        response = self.client.post(
            '/api/propositions/',
            {
                'demande': self.demande.id,
                'prix': '200000',
                'camions': [{'camion': self.camion.id, 'ordre': 1}],
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        self.assertTrue(
            Notification.objects.filter(
                destinataire=self.client_user,
                type_notification=Notification.Type.NOUVELLE_PROPOSITION,
            ).exists()
        )

    def test_proposition_camion_type_different_de_la_demande_rejetee(self):
        # self.demande requiert CITERNE ; on propose une BENNE du même
        # transporteur, aucun camion CITERNE dans la requête -> doit être
        # rejeté avant même d'atteindre la vérification de disponibilité.
        benne = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='BENNE',
            immatriculation='NOTIF-BENNE',
            capacite=15000,
            disponible=True,
        )
        self.client.force_authenticate(user=self.transporteur)

        response = self.client.post(
            '/api/propositions/',
            {
                'demande': self.demande.id,
                'prix': '200000',
                'camions': [{'camion': benne.id, 'ordre': 1}],
            },
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn('camions', response.data)
        self.assertFalse(
            Proposition.objects.filter(demande=self.demande, transporteur=self.transporteur).exists()
        )

    def test_acceptation_proposition_notifie_les_deux_camps(self):
        proposition_acceptee = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.transporteur,
            prix=200000,
        )
        proposition_refusee = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.autre_transporteur,
            prix=210000,
        )

        accepter_proposition_service(proposition_acceptee, self.client_user)

        self.assertTrue(
            Notification.objects.filter(
                destinataire=self.transporteur,
                type_notification=Notification.Type.PROPOSITION_ACCEPTEE,
            ).exists()
        )
        self.assertTrue(
            Notification.objects.filter(
                destinataire=self.autre_transporteur,
                type_notification=Notification.Type.PROPOSITION_REFUSEE,
            ).exists()
        )
        self.assertTrue(
            Notification.objects.filter(
                destinataire=self.client_user,
                type_notification=Notification.Type.MISSION_CREEE,
            ).exists()
        )
        self.assertFalse(
            Notification.objects.filter(
                destinataire=self.autre_transporteur,
                type_notification=Notification.Type.PROPOSITION_ACCEPTEE,
            ).exists()
        )
        proposition_refusee.refresh_from_db()
        self.assertEqual(proposition_refusee.statut, 'REFUSEE')
        # Avant correctif, `demande.statut` restait bloqué sur "OUVERTE" pour
        # toujours : `DemandeTransportListCreateView` (filtrée sur OUVERTE
        # côté transporteur) continuait à proposer "Proposer" sur une
        # demande qui avait pourtant déjà une mission en cours.
        self.demande.refresh_from_db()
        self.assertEqual(self.demande.statut, 'EN_COURS')

    def test_refus_proposition_notifie_le_transporteur_sans_creer_de_mission(self):
        proposition = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.transporteur,
            prix=200000,
        )

        refuser_proposition_service(proposition, self.client_user)

        proposition.refresh_from_db()
        self.assertEqual(proposition.statut, 'REFUSEE')
        self.assertTrue(
            Notification.objects.filter(
                destinataire=self.transporteur,
                type_notification=Notification.Type.PROPOSITION_REFUSEE,
            ).exists()
        )
        self.assertFalse(Mission.objects.filter(demande=self.demande).exists())

    def test_refus_proposition_dun_autre_client_refuse(self):
        proposition = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.transporteur,
            prix=200000,
        )

        with self.assertRaises(PermissionError):
            refuser_proposition_service(proposition, self.autre_transporteur)

    def test_notification_nouvelle_proposition_expose_le_prix_en_direct(self):
        self.client.force_authenticate(user=self.transporteur)
        self.client.post(
            '/api/propositions/',
            {
                'demande': self.demande.id,
                'prix': '1500000',
                'camions': [{'camion': self.camion.id, 'ordre': 1}],
            },
            format='json',
        )
        proposition = Proposition.objects.get(
            demande=self.demande, transporteur=self.transporteur
        )

        self.client.force_authenticate(user=self.client_user)
        response = self.client.get('/api/notifications/')

        notif = next(
            n for n in response.data
            if n['type_notification'] == 'NOUVELLE_PROPOSITION'
        )
        self.assertEqual(notif['proposition'], proposition.id)
        self.assertEqual(notif['proposition_prix'], proposition.prix)

    def test_notification_survit_a_la_suppression_de_la_proposition(self):
        proposition = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.transporteur,
            prix=1500000,
        )
        notifier(
            self.client_user,
            Notification.Type.NOUVELLE_PROPOSITION,
            'Nouvelle proposition : 1500000 XOF.',
            proposition=proposition,
        )

        # Simule un transporteur supprimé : CASCADE sur Proposition.transporteur.
        proposition.delete()

        self.client.force_authenticate(user=self.client_user)
        response = self.client.get('/api/notifications/')

        notif = next(
            n for n in response.data
            if n['type_notification'] == 'NOUVELLE_PROPOSITION'
        )
        # Le texte historique reste affiché, mais le lien vivant (et donc le
        # prix affiché ailleurs dans l'app) est None : rien à ré-ouvrir.
        self.assertIn('1500000', notif['message'])
        self.assertIsNone(notif['proposition'])
        self.assertIsNone(notif['proposition_prix'])

    def test_liste_isolee_par_destinataire(self):
        notifier(self.transporteur, Notification.Type.NOUVELLE_DEMANDE, 'Pour le transporteur')
        notifier(self.client_user, Notification.Type.MISSION_CREEE, 'Pour le client')

        self.client.force_authenticate(user=self.transporteur)
        response = self.client.get('/api/notifications/')

        self.assertEqual(response.status_code, 200)
        messages = [item['message'] for item in response.data]
        self.assertIn('Pour le transporteur', messages)
        self.assertNotIn('Pour le client', messages)

    def test_marquer_lue(self):
        notification = notifier(
            self.transporteur, Notification.Type.NOUVELLE_DEMANDE, 'Test'
        )
        self.client.force_authenticate(user=self.transporteur)

        response = self.client.post(f'/api/notifications/{notification.id}/lire/')

        self.assertEqual(response.status_code, 200)
        notification.refresh_from_db()
        self.assertTrue(notification.lue)

    def test_marquer_lue_notification_dun_autre_404(self):
        notification = notifier(
            self.transporteur, Notification.Type.NOUVELLE_DEMANDE, 'Test'
        )
        self.client.force_authenticate(user=self.autre_transporteur)

        response = self.client.post(f'/api/notifications/{notification.id}/lire/')

        self.assertEqual(response.status_code, 404)
        notification.refresh_from_db()
        self.assertFalse(notification.lue)

    def test_marquer_toutes_lues(self):
        notifier(self.transporteur, Notification.Type.NOUVELLE_DEMANDE, 'A')
        notifier(self.transporteur, Notification.Type.NOUVELLE_DEMANDE, 'B')
        notifier(self.autre_transporteur, Notification.Type.NOUVELLE_DEMANDE, 'C')

        self.client.force_authenticate(user=self.transporteur)
        response = self.client.post('/api/notifications/lire-toutes/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            Notification.objects.filter(destinataire=self.transporteur, lue=False).count(),
            0,
        )
        self.assertEqual(
            Notification.objects.filter(destinataire=self.autre_transporteur, lue=False).count(),
            1,
        )

    def test_compteur_dashboard_transporteur(self):
        notifier(self.transporteur, Notification.Type.NOUVELLE_DEMANDE, 'A')
        notifier(self.transporteur, Notification.Type.NOUVELLE_DEMANDE, 'B')

        self.client.force_authenticate(user=self.transporteur)
        response = self.client.get('/api/transporteur/dashboard/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['notifications_non_lues'], 2)


class ChauffeurMissionActionTests(TestCase):
    """`chauffeur_demarrer_mission`/`chauffeur_terminer_mission` — les
    équivalents de `accepter_mission`/`terminer_mission` ouverts par
    `chauffeur_id` (pas de JWT côté chauffeur), autorisés par appartenance
    à la mission (`MissionCamion.chauffeur_id`) plutôt que par
    `request.user`."""

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-cma',
            password='secret123',
            telephone='0600000050',
            type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-cma',
            password='secret123',
            telephone='0600000051',
            type_compte='ENTREPRISE',
        )
        self.camion = Camion.objects.create(
            proprietaire=self.transporteur,
            type_camion='CITERNE',
            immatriculation='CMA-001',
            capacite=20000,
            disponible=True,
        )
        self.chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Fatou',
            telephone='0600000052',
            numero_permis='PERMIS-CMA-1',
            code_acces='1234',
            disponible=True,
        )
        self.autre_chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur,
            nom='Autre',
            telephone='0600000053',
            numero_permis='PERMIS-CMA-2',
            code_acces='5678',
            disponible=True,
        )
        self.demande = DemandeTransport.objects.create(
            client=self.client_user,
            type_camion='CITERNE',
            ville_depart='Bamako',
            ville_arrivee='Ségou',
            quantite=5000,
            date_chargement='2026-08-08',
            unite='litres',
            statut='EN_COURS',
        )
        proposition = Proposition.objects.create(
            demande=self.demande,
            transporteur=self.transporteur,
            prix=150000,
        )
        self.mission = Mission.objects.create(
            demande=self.demande,
            proposition=proposition,
            client=self.client_user,
            transporteur=self.transporteur,
            prix_final=150000,
        )
        MissionCamion.objects.create(
            mission=self.mission,
            camion=self.camion,
            chauffeur=self.chauffeur,
        )

    def test_liste_expose_mission_id_et_statut(self):
        response = self.client.get(
            f'/api/chauffeur/{self.chauffeur.id}/missions/',
            {'code_acces': self.chauffeur.code_acces},
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data[0]['mission_id'], self.mission.id)
        self.assertEqual(response.data[0]['mission_statut'], 'PLANIFIEE')
        self.assertEqual(response.data[0]['ville_depart'], 'Bamako')

    def test_liste_refuse_mauvais_code_acces(self):
        response = self.client.get(
            f'/api/chauffeur/{self.chauffeur.id}/missions/',
            {'code_acces': 'faux-code'},
        )

        self.assertEqual(response.status_code, 403)

    def test_demarrer_passe_en_cours_et_bloque_camion_et_chauffeur(self):
        response = self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/demarrer/',
            {'code_acces': self.chauffeur.code_acces},
        )

        self.assertEqual(response.status_code, 200)

        self.mission.refresh_from_db()
        self.camion.refresh_from_db()
        self.chauffeur.refresh_from_db()

        self.assertEqual(self.mission.statut, 'EN_COURS')
        self.assertFalse(self.camion.disponible)
        self.assertFalse(self.chauffeur.disponible)

    def test_demarrer_refuse_mauvais_code_acces(self):
        # chauffeur_id/mission_id sont des entiers séquentiels devinables :
        # sans revérifier le code d'accès ici, n'importe qui les connaissant
        # pouvait démarrer une vraie mission (et donc, via terminer, en
        # déclencher la libération du paiement) sans jamais le connaître.
        response = self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/demarrer/',
            {'code_acces': 'faux-code'},
        )

        self.assertEqual(response.status_code, 403)
        self.mission.refresh_from_db()
        self.assertEqual(self.mission.statut, 'PLANIFIEE')

    def test_demarrer_notifie_le_transporteur(self):
        self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/demarrer/',
            {'code_acces': self.chauffeur.code_acces},
        )

        self.assertTrue(
            Notification.objects.filter(
                destinataire=self.transporteur,
                type_notification=Notification.Type.MISSION_DEMARREE,
            ).exists()
        )

    def test_demarrer_chauffeur_non_affecte_403(self):
        response = self.client.post(
            f'/api/chauffeur/{self.autre_chauffeur.id}/missions/{self.mission.id}/demarrer/',
            {'code_acces': self.autre_chauffeur.code_acces},
        )

        self.assertEqual(response.status_code, 403)

        self.mission.refresh_from_db()
        self.assertEqual(self.mission.statut, 'PLANIFIEE')

    def test_demarrer_mission_deja_en_cours_400(self):
        self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/demarrer/',
            {'code_acces': self.chauffeur.code_acces},
        )
        response = self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/demarrer/',
            {'code_acces': self.chauffeur.code_acces},
        )

        self.assertEqual(response.status_code, 400)

    def test_terminer_avant_demarrage_400(self):
        response = self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/terminer/',
            {'code_acces': self.chauffeur.code_acces},
        )

        self.assertEqual(response.status_code, 400)

    def test_terminer_libere_camion_et_chauffeur(self):
        self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/demarrer/',
            {'code_acces': self.chauffeur.code_acces},
        )
        response = self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/terminer/',
            {'code_acces': self.chauffeur.code_acces},
        )

        self.assertEqual(response.status_code, 200)

        self.mission.refresh_from_db()
        self.camion.refresh_from_db()
        self.chauffeur.refresh_from_db()

        self.assertEqual(self.mission.statut, 'TERMINEE')
        self.assertTrue(self.camion.disponible)
        self.assertTrue(self.chauffeur.disponible)

    def test_terminer_refuse_mauvais_code_acces(self):
        self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/demarrer/',
            {'code_acces': self.chauffeur.code_acces},
        )
        response = self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/terminer/',
            {'code_acces': 'faux-code'},
        )

        self.assertEqual(response.status_code, 403)
        self.mission.refresh_from_db()
        self.assertEqual(self.mission.statut, 'EN_COURS')

    def test_terminer_notifie_le_transporteur(self):
        self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/demarrer/',
            {'code_acces': self.chauffeur.code_acces},
        )
        self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/terminer/',
            {'code_acces': self.chauffeur.code_acces},
        )

        self.assertTrue(
            Notification.objects.filter(
                destinataire=self.transporteur,
                type_notification=Notification.Type.MISSION_TERMINEE,
            ).exists()
        )

    def test_terminer_chauffeur_non_affecte_403(self):
        self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/{self.mission.id}/demarrer/',
            {'code_acces': self.chauffeur.code_acces},
        )
        response = self.client.post(
            f'/api/chauffeur/{self.autre_chauffeur.id}/missions/{self.mission.id}/terminer/',
            {'code_acces': self.autre_chauffeur.code_acces},
        )

        self.assertEqual(response.status_code, 403)

    def test_mission_introuvable_404(self):
        response = self.client.post(
            f'/api/chauffeur/{self.chauffeur.id}/missions/999999/demarrer/',
            {'code_acces': self.chauffeur.code_acces},
        )

        self.assertEqual(response.status_code, 404)


def _creer_mission_avec_prix(client_user, transporteur, prix_final=100000, pays_depart='ML'):
    """Helper local aux tests de paiement : les autres classes de ce fichier
    construisent la même pile (demande -> proposition -> mission) à la main
    dans chaque `setUp`, mais les 4 classes de paiement ci-dessous en ont
    toutes besoin à l'identique avec un seul paramètre qui varie (le prix) —
    ça justifie l'extraction ici, contrairement aux setUp existants qui
    varient chacun assez pour ne pas se factoriser proprement."""
    demande = DemandeTransport.objects.create(
        client=client_user,
        type_camion='CITERNE',
        ville_depart='Bamako',
        ville_arrivee='Ségou',
        quantite=5000,
        date_chargement='2026-08-08',
        unite='litres',
        statut='EN_COURS',
        pays_depart=pays_depart,
    )
    proposition = Proposition.objects.create(
        demande=demande,
        transporteur=transporteur,
        prix=prix_final,
    )
    return Mission.objects.create(
        demande=demande,
        proposition=proposition,
        client=client_user,
        transporteur=transporteur,
        prix_final=prix_final,
    )


class CalculerCommissionTests(TestCase):

    def test_commission_5_pourcent(self):
        commission, net = calculer_commission(100000, taux=5)
        self.assertEqual(commission, 5000)
        self.assertEqual(net, 95000)


class PaiementCarteFlowTests(TestCase):
    """Mode CARTE via le simulateur (aucun PSP réel branché, cf.
    gateway_paiement.py) : ENCAISSE/SECURISE quasi simultanés dès la
    confirmation webhook, pas de validation admin à ce stade."""

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-pcf', password='secret123',
            telephone='0700000001', type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-pcf', password='secret123',
            telephone='0700000002', type_compte='ENTREPRISE',
        )
        self.admin = User.objects.create_user(
            username='admin-pcf', password='secret123',
            telephone='0700000003', type_compte='ADMIN',
        )
        self.mission = _creer_mission_avec_prix(self.client_user, self.transporteur, prix_final=100000)
        self.client.force_authenticate(user=self.client_user)

    def test_initier_paiement_carte_cree_une_reference_sans_page_externe(self):
        """Depuis le passage au formulaire carte intégré, plus de
        `checkout_url` à ouvrir : la transaction est initiée côté passerelle
        (référence stockée) mais tout se passe ensuite dans l'app via
        `confirmer_paiement_carte`."""
        response = self.client.post(
            f'/api/missions/{self.mission.id}/paiement/initier/', {'mode': 'CARTE'}
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['statut'], 'EN_ATTENTE')
        self.assertEqual(response.data['commission_montant'], '5000.00')
        self.assertEqual(response.data['montant_transporteur'], '95000.00')
        self.assertNotIn('checkout_url', response.data)
        self.assertTrue(response.data['reference_externe'])

    def test_seul_le_client_de_la_mission_peut_initier(self):
        self.client.force_authenticate(user=self.transporteur)
        response = self.client.post(
            f'/api/missions/{self.mission.id}/paiement/initier/', {'mode': 'CARTE'}
        )
        self.assertEqual(response.status_code, 403)

    def test_deuxieme_initiation_refusee(self):
        creer_paiement_service(self.mission, 'CARTE', self.client_user)
        response = self.client.post(
            f'/api/missions/{self.mission.id}/paiement/initier/', {'mode': 'CARTE'}
        )
        self.assertEqual(response.status_code, 400)

    def test_webhook_reussi_securise_le_paiement(self):
        paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)
        initier_paiement_carte_service(paiement)
        paiement.refresh_from_db()

        response = self.client.post(
            '/api/paiements/webhook/',
            {'reference': paiement.reference_externe, 'statut': 'REUSSI'},
        )

        self.assertEqual(response.status_code, 200)
        paiement.refresh_from_db()
        self.assertEqual(paiement.statut, Paiement.Statut.SECURISE)
        self.assertIsNotNone(paiement.date_securisation)

    def test_webhook_echec_marque_le_paiement_en_echec(self):
        paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)
        initier_paiement_carte_service(paiement)
        paiement.refresh_from_db()

        confirmer_paiement_carte_service(paiement.reference_externe, 'ECHEC')

        paiement.refresh_from_db()
        self.assertEqual(paiement.statut, Paiement.Statut.ECHEC)

    def test_confirmer_carte_securise_et_enregistre_les_metadonnees(self):
        """Flux du formulaire carte intégré : le client confirme directement
        depuis l'app (pas de webhook), et les métadonnées d'affichage (marque,
        4 derniers chiffres, expiration) sont enregistrées — jamais le numéro
        complet ni le CVV, qui ne sont pas dans ce payload."""
        response = self.client.post(
            f'/api/missions/{self.mission.id}/paiement/initier/', {'mode': 'CARTE'}
        )
        paiement_id = response.data['id']

        response = self.client.post(
            f'/api/paiements/{paiement_id}/confirmer-carte/',
            {
                'carte_marque': 'VISA',
                'carte_dernier4': '4242',
                'carte_expiration': '08/29',
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['statut'], 'SECURISE')
        self.assertEqual(response.data['carte_marque'], 'VISA')
        self.assertEqual(response.data['carte_dernier4'], '4242')
        self.assertEqual(response.data['carte_expiration'], '08/29')

    def test_confirmer_carte_refuse_pour_un_autre_client(self):
        response = self.client.post(
            f'/api/missions/{self.mission.id}/paiement/initier/', {'mode': 'CARTE'}
        )
        paiement_id = response.data['id']

        self.client.force_authenticate(user=self.transporteur)
        response = self.client.post(f'/api/paiements/{paiement_id}/confirmer-carte/', {})

        self.assertEqual(response.status_code, 403)

    def test_confirmer_carte_refuse_en_mode_manuel(self):
        paiement = creer_paiement_service(self.mission, 'MANUEL', self.client_user)

        response = self.client.post(f'/api/paiements/{paiement.id}/confirmer-carte/', {})

        self.assertEqual(response.status_code, 400)

    def test_confirmer_carte_deja_traite_ne_releve_pas_derreur(self):
        response = self.client.post(
            f'/api/missions/{self.mission.id}/paiement/initier/', {'mode': 'CARTE'}
        )
        paiement_id = response.data['id']

        premiere = self.client.post(
            f'/api/paiements/{paiement_id}/confirmer-carte/',
            {'carte_marque': 'VISA', 'carte_dernier4': '4242', 'carte_expiration': '08/29'},
        )
        self.assertEqual(premiere.status_code, 200)

        deuxieme = self.client.post(f'/api/paiements/{paiement_id}/confirmer-carte/', {})
        self.assertEqual(deuxieme.status_code, 200)
        self.assertEqual(deuxieme.data['statut'], 'SECURISE')

    def test_terminer_mission_libere_automatiquement_le_paiement_securise(self):
        paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)
        initier_paiement_carte_service(paiement)
        paiement.refresh_from_db()
        confirmer_paiement_carte_service(paiement.reference_externe, 'REUSSI')

        terminer_mission_service(self.mission)

        paiement.refresh_from_db()
        self.assertEqual(paiement.statut, Paiement.Statut.LIBERE)
        self.assertIsNotNone(paiement.date_liberation)

    def test_admin_peut_verser_un_paiement_libere(self):
        paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)
        initier_paiement_carte_service(paiement)
        paiement.refresh_from_db()
        confirmer_paiement_carte_service(paiement.reference_externe, 'REUSSI')
        terminer_mission_service(self.mission)

        self.client.force_authenticate(user=self.admin)
        response = self.client.post(
            f'/api/paiements/{paiement.id}/verser/', {'reference': 'VIR-001'}
        )

        self.assertEqual(response.status_code, 200)
        paiement.refresh_from_db()
        self.assertEqual(paiement.statut, Paiement.Statut.VERSE)

    def test_non_admin_ne_peut_pas_verser(self):
        paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)
        initier_paiement_carte_service(paiement)
        paiement.refresh_from_db()
        confirmer_paiement_carte_service(paiement.reference_externe, 'REUSSI')
        terminer_mission_service(self.mission)

        response = self.client.post(f'/api/paiements/{paiement.id}/verser/', {})

        self.assertEqual(response.status_code, 403)
        paiement.refresh_from_db()
        self.assertEqual(paiement.statut, Paiement.Statut.LIBERE)


class PaiementManuelFlowTests(TestCase):
    """Mode MANUEL : un agent AfriFlotte encaisse physiquement, mais le
    paiement ne devient SECURISE qu'après validation admin explicite —
    contrairement à CARTE où le PSP a déjà fait cette vérification."""

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-pmf', password='secret123',
            telephone='0700000010', type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-pmf', password='secret123',
            telephone='0700000011', type_compte='ENTREPRISE',
        )
        self.agent = User.objects.create_user(
            username='agent-pmf', password='secret123',
            telephone='0700000012', type_compte='AGENT',
        )
        self.admin = User.objects.create_user(
            username='admin-pmf', password='secret123',
            telephone='0700000013', type_compte='ADMIN',
        )
        self.mission = _creer_mission_avec_prix(self.client_user, self.transporteur, prix_final=200000)
        self.paiement = creer_paiement_service(self.mission, 'MANUEL', self.client_user)

    def test_transporteur_ne_peut_pas_encaisser(self):
        self.client.force_authenticate(user=self.transporteur)
        response = self.client.post(
            f'/api/paiements/{self.paiement.id}/encaisser-manuel/', {'reference': 'CASH-1'}
        )
        self.assertEqual(response.status_code, 403)

    def test_agent_encaisse_reste_en_attente_de_validation(self):
        self.client.force_authenticate(user=self.agent)
        response = self.client.post(
            f'/api/paiements/{self.paiement.id}/encaisser-manuel/',
            {'reference': 'CASH-1', 'preuve': _fichier_image()},
            format='multipart',
        )

        self.assertEqual(response.status_code, 200)
        self.paiement.refresh_from_db()
        self.assertEqual(self.paiement.statut, Paiement.Statut.ENCAISSE)
        self.assertEqual(self.paiement.agent_id, self.agent.id)
        self.assertEqual(self.paiement.preuves.count(), 1)

    def test_non_admin_ne_peut_pas_valider(self):
        encaisser_paiement_manuel_service(self.paiement, self.agent, 'CASH-1')

        self.client.force_authenticate(user=self.agent)
        response = self.client.post(f'/api/paiements/{self.paiement.id}/valider/', {})

        self.assertEqual(response.status_code, 403)

    def test_admin_valide_puis_terminer_libere_puis_verse(self):
        encaisser_paiement_manuel_service(self.paiement, self.agent, 'CASH-1')

        self.client.force_authenticate(user=self.admin)
        response = self.client.post(f'/api/paiements/{self.paiement.id}/valider/', {})
        self.assertEqual(response.status_code, 200)

        self.paiement.refresh_from_db()
        self.assertEqual(self.paiement.statut, Paiement.Statut.SECURISE)

        terminer_mission_service(self.mission)
        self.paiement.refresh_from_db()
        self.assertEqual(self.paiement.statut, Paiement.Statut.LIBERE)

        response = self.client.post(f'/api/paiements/{self.paiement.id}/verser/', {})
        self.assertEqual(response.status_code, 200)
        self.paiement.refresh_from_db()
        self.assertEqual(self.paiement.statut, Paiement.Statut.VERSE)

    def test_validation_avant_encaissement_refusee(self):
        with self.assertRaises(ValueError):
            valider_paiement_manuel_service(self.paiement, self.admin)

    def test_agent_voit_les_paiements_manuels_en_attente_de_tout_le_monde(self):
        """`AgentPaiementsView` n'est PAS filtré par propriété (contrairement
        à `MesPaiementsView`) : un agent est du personnel AfriFlotte, pas une
        partie à la mission — il doit voir ce paiement bien qu'il ne soit ni
        le client ni le transporteur de `self.mission`."""
        self.client.force_authenticate(user=self.agent)
        response = self.client.get('/api/agent/paiements-a-encaisser/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], self.paiement.id)

    def test_transporteur_ne_voit_rien_sur_la_file_agent(self):
        self.client.force_authenticate(user=self.transporteur)
        response = self.client.get('/api/agent/paiements-a-encaisser/')

        self.assertEqual(response.status_code, 403)


class RemboursementTests(TestCase):

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-remb', password='secret123',
            telephone='0700000020', type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-remb', password='secret123',
            telephone='0700000021', type_compte='ENTREPRISE',
        )
        self.mission = _creer_mission_avec_prix(self.client_user, self.transporteur, prix_final=100000)

    def test_annulation_sans_paiement_ne_plante_pas(self):
        """Le point d'accroche ajouté dans `refuser_mission` doit rester un
        no-op silencieux pour toute mission sans Paiement — c'est le cas de
        toutes les missions créées avant ce module."""
        self.client.force_authenticate(user=self.transporteur)
        response = self.client.post(f'/api/missions/{self.mission.id}/refuser/')

        self.assertEqual(response.status_code, 200)
        self.mission.refresh_from_db()
        self.assertEqual(self.mission.statut, Mission.Statut.ANNULEE)

    def test_annulation_rembourse_paiement_securise(self):
        paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)
        initier_paiement_carte_service(paiement)
        paiement.refresh_from_db()
        confirmer_paiement_carte_service(paiement.reference_externe, 'REUSSI')

        self.client.force_authenticate(user=self.transporteur)
        response = self.client.post(f'/api/missions/{self.mission.id}/refuser/')

        self.assertEqual(response.status_code, 200)
        paiement.refresh_from_db()
        self.assertEqual(paiement.statut, Paiement.Statut.REMBOURSE)
        self.assertIsNotNone(paiement.date_remboursement)

    def test_annulation_ne_touche_pas_un_paiement_en_attente(self):
        """Rien à rembourser tant que le client n'a pas payé : le paiement
        reste EN_ATTENTE, `rembourser_paiement_service` ne doit pas le
        transformer en REMBOURSE."""
        paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)

        self.client.force_authenticate(user=self.transporteur)
        self.client.post(f'/api/missions/{self.mission.id}/refuser/')

        paiement.refresh_from_db()
        self.assertEqual(paiement.statut, Paiement.Statut.EN_ATTENTE)

    def test_remboursement_sans_api_psp_marque_le_motif_comme_manuel(self):
        """Certains PSP (PayDunya) n'ont aucune API de remboursement liée à
        la transaction d'origine : `rembourser_transaction` renvoie `False`,
        et le paiement doit quand même se conclure (REMBOURSE) mais avec un
        motif signalant qu'un geste manuel reste nécessaire."""
        paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)
        initier_paiement_carte_service(paiement)
        paiement.refresh_from_db()
        confirmer_paiement_carte_service(paiement.reference_externe, 'REUSSI')

        with patch('core.services.get_gateway') as mock_get_gateway:
            mock_get_gateway.return_value.rembourser_transaction.return_value = False

            self.client.force_authenticate(user=self.transporteur)
            response = self.client.post(f'/api/missions/{self.mission.id}/refuser/')

        self.assertEqual(response.status_code, 200)
        paiement.refresh_from_db()
        self.assertEqual(paiement.statut, Paiement.Statut.REMBOURSE)
        self.assertIn('manuel', paiement.motif_remboursement.lower())


class PayDunyaGatewayAdapterTests(TestCase):
    """`PayDunyaGatewayAdapter` (core/gateway_paiement.py) — tous les appels
    HTTP réels sont mockés, aucune vraie clé PayDunya n'est nécessaire pour
    ces tests."""

    def setUp(self):
        self.adaptateur = PayDunyaGatewayAdapter()
        self.transporteur = User.objects.create_user(
            username='transporteur-pd', password='secret123',
            telephone='0700000030', type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-pd', password='secret123',
            telephone='0700000031', type_compte='ENTREPRISE',
        )
        self.mission = _creer_mission_avec_prix(self.client_user, self.transporteur, prix_final=100000)
        self.paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)

    @patch('core.gateway_paiement.requests.post')
    def test_creer_transaction_succes(self, mock_post):
        mock_post.return_value = Mock(json=lambda: {
            'response_code': '00',
            'response_text': 'https://paydunya.com/checkout/abc123',
            'token': 'TOKEN-ABC123',
        })

        resultat = self.adaptateur.creer_transaction(self.paiement)

        self.assertEqual(resultat['reference'], 'TOKEN-ABC123')
        self.assertEqual(resultat['checkout_url'], 'https://paydunya.com/checkout/abc123')
        # Mission au Mali -> devise déjà XOF, pas de conversion à tracer.
        self.assertNotIn('montant_xof', resultat)

    @patch('core.gateway_paiement.requests.post')
    def test_creer_transaction_convertit_vers_xof_pour_une_devise_etrangere(self, mock_post):
        """PayDunya ne facture qu'en XOF (aucun paramètre de devise sur son
        API) : une mission au Ghana (prix en GHS) doit être convertie avant
        l'envoi, sous peine de facturer 1000 XOF pour un prix de 1000 GHS."""
        mock_post.return_value = Mock(json=lambda: {
            'response_code': '00',
            'response_text': 'https://paydunya.com/checkout/ghs1',
            'token': 'TOKEN-GHS-1',
        })
        mission_gh = _creer_mission_avec_prix(
            self.client_user, self.transporteur, prix_final=1000, pays_depart='GH',
        )
        paiement_gh = creer_paiement_service(mission_gh, 'CARTE', self.client_user)
        self.assertEqual(paiement_gh.devise, 'GHS')

        resultat = self.adaptateur.creer_transaction(paiement_gh)

        montant_envoye = mock_post.call_args.kwargs['json']['invoice']['total_amount']
        self.assertEqual(montant_envoye, 49000.0)
        self.assertEqual(resultat['montant_xof'], Decimal('49000'))

    @patch('core.gateway_paiement.requests.post')
    def test_creer_transaction_restreint_les_canaux_au_pays_du_client(self, mock_post):
        """Sans le paramètre `channels`, PayDunya affiche par défaut tout ce
        qui est autorisé sur le compte marchand (ex. Wave Sénégal à un
        client malien) — creer_transaction doit toujours le restreindre au
        pays réel de la mission."""
        mock_post.return_value = Mock(json=lambda: {
            'response_code': '00',
            'response_text': 'https://paydunya.com/checkout/ml1',
            'token': 'TOKEN-ML-1',
        })

        self.adaptateur.creer_transaction(self.paiement)  # mission ML (setUp)

        canaux_envoyes = mock_post.call_args.kwargs['json']['invoice']['channels']
        self.assertEqual(canaux_envoyes, ['card', 'orange-money-mali'])

    @patch('core.gateway_paiement.requests.post')
    def test_creer_transaction_carte_seule_pour_pays_sans_mobile_money_paydunya(self, mock_post):
        mock_post.return_value = Mock(json=lambda: {
            'response_code': '00',
            'response_text': 'https://paydunya.com/checkout/gh1',
            'token': 'TOKEN-GH-1',
        })
        mission_gh = _creer_mission_avec_prix(
            self.client_user, self.transporteur, prix_final=1000, pays_depart='GH',
        )
        paiement_gh = creer_paiement_service(mission_gh, 'CARTE', self.client_user)

        self.adaptateur.creer_transaction(paiement_gh)

        canaux_envoyes = mock_post.call_args.kwargs['json']['invoice']['channels']
        self.assertEqual(canaux_envoyes, ['card'])

    @patch('core.gateway_paiement.requests.post')
    def test_creer_transaction_echec_leve_une_exception(self, mock_post):
        mock_post.return_value = Mock(json=lambda: {
            'response_code': '01',
            'response_text': 'Clés invalides.',
        })

        with self.assertRaises(PayDunyaInvalide):
            self.adaptateur.creer_transaction(self.paiement)

    @patch('core.gateway_paiement.requests.get')
    def test_verifier_transaction_mappe_les_statuts(self, mock_get):
        for statut_paydunya, attendu in [
            ('completed', 'REUSSI'),
            ('failed', 'ECHEC'),
            ('cancelled', 'ECHEC'),
            ('pending', 'EN_ATTENTE'),
            ('autre-chose-inconnu', 'EN_ATTENTE'),
        ]:
            mock_get.return_value = Mock(json=lambda s=statut_paydunya: {'status': s})
            self.assertEqual(self.adaptateur.verifier_transaction('TOKEN-X'), attendu)

    @patch('core.gateway_paiement.requests.get')
    def test_verifier_transaction_panne_reseau_retombe_en_attente(self, mock_get):
        """Une panne réseau/réponse malformée ne doit jamais faire échouer à
        tort un paiement réel — mieux vaut rester EN_ATTENTE et réessayer."""
        import requests as requests_module
        mock_get.side_effect = requests_module.RequestException('boom')

        self.assertEqual(self.adaptateur.verifier_transaction('TOKEN-X'), 'EN_ATTENTE')

    def test_rembourser_transaction_toujours_false(self):
        """Pas d'API de remboursement liée à la transaction d'origine chez
        PayDunya — voir core/services.py:rembourser_paiement_service pour la
        gestion du remboursement manuel qui en découle."""
        self.assertFalse(self.adaptateur.rembourser_transaction('TOKEN-X', 1000))

    @override_settings(PAYDUNYA_MASTER_KEY='cle-maitre-test')
    def test_verifier_authenticite_webhook(self):
        import hashlib
        hash_valide = hashlib.sha512('cle-maitre-test'.encode()).hexdigest()

        self.assertTrue(self.adaptateur.verifier_authenticite_webhook({'hash': hash_valide}))
        self.assertFalse(self.adaptateur.verifier_authenticite_webhook({'hash': 'faux-hash'}))
        self.assertFalse(self.adaptateur.verifier_authenticite_webhook({}))


@override_settings(PAIEMENT_GATEWAY='paydunya', PAYDUNYA_MASTER_KEY='cle-maitre-test')
class PaiementWebhookPayDunyaTests(TestCase):
    """Le webhook ne doit jamais faire confiance au statut du payload reçu —
    seule une ré-interrogation de PayDunya (`verifier_transaction`) fait foi,
    conformément à la doc PayDunya elle-même."""

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-wh', password='secret123',
            telephone='0700000040', type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-wh', password='secret123',
            telephone='0700000041', type_compte='ENTREPRISE',
        )
        self.mission = _creer_mission_avec_prix(self.client_user, self.transporteur, prix_final=100000)
        self.paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)
        self.paiement.reference_externe = 'TOKEN-WEBHOOK-TEST'
        self.paiement.save(update_fields=['reference_externe'])

    def _hash_valide(self):
        import hashlib
        return hashlib.sha512('cle-maitre-test'.encode()).hexdigest()

    @patch('core.gateway_paiement.requests.get')
    def test_webhook_ignore_le_statut_du_payload_et_reverifie(self, mock_get):
        """Le payload prétend "completed" mais la ré-vérification serveur
        dit "pending" : c'est cette dernière qui doit primer, le paiement ne
        doit donc PAS être sécurisé."""
        mock_get.return_value = Mock(json=lambda: {'status': 'pending'})

        response = self.client.post(
            '/api/paiements/webhook/',
            {'data': f'{{"token": "TOKEN-WEBHOOK-TEST", "status": "completed", "hash": "{self._hash_valide()}"}}'},
        )

        self.assertEqual(response.status_code, 200)
        self.paiement.refresh_from_db()
        self.assertEqual(self.paiement.statut, Paiement.Statut.EN_ATTENTE)

    @patch('core.gateway_paiement.requests.get')
    def test_webhook_securise_quand_la_reverification_confirme(self, mock_get):
        mock_get.return_value = Mock(json=lambda: {'status': 'completed'})

        response = self.client.post(
            '/api/paiements/webhook/',
            {'data': f'{{"token": "TOKEN-WEBHOOK-TEST", "status": "completed", "hash": "{self._hash_valide()}"}}'},
        )

        self.assertEqual(response.status_code, 200)
        self.paiement.refresh_from_db()
        self.assertEqual(self.paiement.statut, Paiement.Statut.SECURISE)

    def test_webhook_refuse_un_hash_invalide(self):
        response = self.client.post(
            '/api/paiements/webhook/',
            {'data': '{"token": "TOKEN-WEBHOOK-TEST", "status": "completed", "hash": "faux"}'},
        )

        self.assertEqual(response.status_code, 403)
        self.paiement.refresh_from_db()
        self.assertEqual(self.paiement.statut, Paiement.Statut.EN_ATTENTE)

    @patch('core.gateway_paiement.requests.get')
    def test_ipn_paydunya_accepte_et_ne_traite_pas_double(self, mock_get):
        mock_get.return_value = Mock(json=lambda: {'status': 'completed'})

        payload = {
            'token': 'TOKEN-WEBHOOK-TEST',
            'status': 'completed',
            'hash': self._hash_valide(),
        }

        reponse1 = self.client.post('/api/payment/ipn/', payload)
        reponse2 = self.client.post('/api/payment/ipn/', payload)

        self.assertEqual(reponse1.status_code, 200)
        self.assertEqual(reponse2.status_code, 200)
        self.paiement.refresh_from_db()
        self.assertEqual(self.paiement.statut, Paiement.Statut.SECURISE)


class LitigeTests(TestCase):

    def setUp(self):
        self.client = APIClient()
        self.transporteur = User.objects.create_user(
            username='transporteur-lit', password='secret123',
            telephone='0700000030', type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-lit', password='secret123',
            telephone='0700000031', type_compte='ENTREPRISE',
        )
        self.admin = User.objects.create_user(
            username='admin-lit', password='secret123',
            telephone='0700000032', type_compte='ADMIN',
        )
        self.autre = User.objects.create_user(
            username='tiers-lit', password='secret123',
            telephone='0700000033', type_compte='ENTREPRISE',
        )
        self.mission = _creer_mission_avec_prix(self.client_user, self.transporteur, prix_final=150000)
        self.paiement = creer_paiement_service(self.mission, 'CARTE', self.client_user)
        initier_paiement_carte_service(self.paiement)
        self.paiement.refresh_from_db()
        confirmer_paiement_carte_service(self.paiement.reference_externe, 'REUSSI')
        self.paiement.refresh_from_db()

    def test_tiers_ne_peut_pas_ouvrir_de_litige(self):
        with self.assertRaises(PermissionError):
            ouvrir_litige_service(self.paiement, self.autre, "Colis endommagé")

    def test_ouverture_litige_bloque_la_liberation_a_la_fin_de_mission(self):
        ouvrir_litige_service(self.paiement, self.client_user, "Colis endommagé")

        terminer_mission_service(self.mission)

        self.paiement.refresh_from_db()
        self.assertEqual(self.paiement.statut, Paiement.Statut.SECURISE)
        self.assertTrue(self.paiement.litige_en_cours)

    def test_resolution_en_faveur_du_transporteur_rejoue_la_liberation(self):
        litige = ouvrir_litige_service(self.paiement, self.client_user, "Colis endommagé")
        terminer_mission_service(self.mission)

        resoudre_litige_service(litige, self.admin, Litige.Statut.RESOLU_TRANSPORTEUR, "Livraison conforme")

        self.paiement.refresh_from_db()
        self.assertFalse(self.paiement.litige_en_cours)
        self.assertEqual(self.paiement.statut, Paiement.Statut.LIBERE)

    def test_resolution_en_faveur_du_client_rembourse(self):
        litige = ouvrir_litige_service(self.paiement, self.transporteur, "Client injoignable")

        resoudre_litige_service(litige, self.admin, Litige.Statut.RESOLU_CLIENT, "Marchandise jamais livrée")

        self.paiement.refresh_from_db()
        self.assertFalse(self.paiement.litige_en_cours)
        self.assertEqual(self.paiement.statut, Paiement.Statut.REMBOURSE)

    def test_non_admin_ne_peut_pas_resoudre(self):
        litige = ouvrir_litige_service(self.paiement, self.client_user, "Colis endommagé")

        with self.assertRaises(PermissionError):
            resoudre_litige_service(litige, self.client_user, Litige.Statut.REJETE)

    def test_notification_paiement_expose_le_montant_en_direct(self):
        notif = Notification.objects.filter(
            destinataire=self.client_user,
            type_notification=Notification.Type.PAIEMENT_SECURISE,
        ).first()

        self.assertIsNotNone(notif)
        self.assertEqual(notif.paiement_id, self.paiement.id)


class AdminPlateformeViewsTests(TestCase):
    """Les 5 vues admin "plateforme" (non scopées à request.user) qui
    alimentent les cartes cliquables de dashboard_admin.dart :
    AdminUtilisateursView/AdminChauffeursView/AdminCamionsView/
    AdminMissionsView/AdminDemandesView."""

    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            username='admin-plateforme', password='secret123',
            telephone='0600000200', type_compte='ADMIN',
        )
        self.transporteur = User.objects.create_user(
            username='transporteur-plateforme', password='secret123',
            telephone='0600000201', type_compte='TRANSPORTEUR',
        )
        self.client_user = User.objects.create_user(
            username='client-plateforme', password='secret123',
            telephone='0600000202', type_compte='ENTREPRISE',
        )
        self.camion = Camion.objects.create(
            proprietaire=self.transporteur, type_camion='CITERNE',
            immatriculation='PLAT-001', capacite=20000, disponible=True,
        )
        self.chauffeur = Chauffeur.objects.create(
            transporteur=self.transporteur, nom='Awa', telephone='0600000203',
            numero_permis='PERMIS-PLAT-1',
        )
        self.demande = DemandeTransport.objects.create(
            client=self.client_user, type_camion='CITERNE',
            ville_depart='Bamako', ville_arrivee='Kayes', quantite=5000,
            date_chargement='2026-08-08', unite='litres', statut='OUVERTE',
        )
        proposition = Proposition.objects.create(
            demande=self.demande, transporteur=self.transporteur, prix=150000,
        )
        self.mission = Mission.objects.create(
            demande=self.demande, proposition=proposition,
            client=self.client_user, transporteur=self.transporteur,
            prix_final=150000, statut='TERMINEE',
        )

    def test_utilisateurs_refuse_non_admin(self):
        self.client.force_authenticate(user=self.transporteur)
        response = self.client.get('/api/admin/utilisateurs/?type_compte=TRANSPORTEUR')
        self.assertEqual(response.status_code, 403)

    def test_utilisateurs_exige_type_compte(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/admin/utilisateurs/')
        self.assertEqual(response.status_code, 400)

    def test_utilisateurs_liste_les_transporteurs(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/admin/utilisateurs/?type_compte=TRANSPORTEUR')
        self.assertEqual(response.status_code, 200)
        ids = [u['id'] for u in response.data]
        self.assertIn(self.transporteur.id, ids)
        self.assertNotIn(self.client_user.id, ids)
        self.assertNotIn(self.admin.id, ids)

    def test_utilisateurs_liste_les_entreprises(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/admin/utilisateurs/?type_compte=ENTREPRISE')
        self.assertEqual(response.status_code, 200)
        ids = [u['id'] for u in response.data]
        self.assertIn(self.client_user.id, ids)
        self.assertNotIn(self.transporteur.id, ids)

    def test_chauffeurs_refuse_non_admin(self):
        self.client.force_authenticate(user=self.transporteur)
        response = self.client.get('/api/admin/chauffeurs/')
        self.assertEqual(response.status_code, 403)

    def test_chauffeurs_expose_le_transporteur_proprietaire(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/admin/chauffeurs/')
        self.assertEqual(response.status_code, 200)
        chauffeur_data = next(c for c in response.data if c['id'] == self.chauffeur.id)
        self.assertEqual(chauffeur_data['transporteur_nom'], self.transporteur.username)

    def test_camions_refuse_non_admin(self):
        self.client.force_authenticate(user=self.transporteur)
        response = self.client.get('/api/admin/camions/')
        self.assertEqual(response.status_code, 403)

    def test_camions_liste_toute_la_plateforme(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/admin/camions/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(self.camion.id, [c['id'] for c in response.data])

    def test_missions_refuse_non_admin(self):
        self.client.force_authenticate(user=self.client_user)
        response = self.client.get('/api/admin/missions/')
        self.assertEqual(response.status_code, 403)

    def test_missions_expose_client_et_transporteur(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/admin/missions/')
        self.assertEqual(response.status_code, 200)
        mission_data = next(m for m in response.data if m['id'] == self.mission.id)
        self.assertEqual(mission_data['client_nom'], self.client_user.username)
        self.assertEqual(mission_data['transporteur_nom'], self.transporteur.username)

    def test_demandes_refuse_non_admin(self):
        self.client.force_authenticate(user=self.transporteur)
        response = self.client.get('/api/admin/demandes/')
        self.assertEqual(response.status_code, 403)

    def test_demandes_expose_le_client(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/admin/demandes/')
        self.assertEqual(response.status_code, 200)
        demande_data = next(d for d in response.data if d['id'] == self.demande.id)
        self.assertEqual(demande_data['client_nom'], self.client_user.username)
