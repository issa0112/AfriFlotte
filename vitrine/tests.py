import os
import shutil
import tempfile

from django.test import TestCase, override_settings


class LandingViewTests(TestCase):

    def test_page_accueil_repond_200_avec_le_bon_contenu(self):
        response = self.client.get('/')

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'AfriFlotte')
        self.assertContains(response, 'Transportez plus. Trouvez plus. Développez plus.')
        self.assertContains(response, 'Se connecter')
        self.assertContains(response, 'Créer un compte')

    def test_couverture_liste_les_15_pays_cedeao(self):
        response = self.client.get('/')

        self.assertContains(response, 'Mali')
        self.assertContains(response, 'Nigeria')
        self.assertContains(response, 'Cap-Vert')

    def test_telechargement_desactive_sans_fichier_apk(self):
        """Pas de faux lien de téléchargement tant qu'aucun APK n'est déposé
        sous media/apk/ — cf. plan validé."""
        dossier_vide = tempfile.mkdtemp()
        try:
            with override_settings(MEDIA_ROOT=dossier_vide):
                response = self.client.get('/')
            self.assertContains(response, 'Bientôt disponible')
        finally:
            shutil.rmtree(dossier_vide)

    def test_telechargement_actif_quand_le_fichier_existe(self):
        dossier_temp = tempfile.mkdtemp()
        try:
            os.makedirs(os.path.join(dossier_temp, 'apk'))
            chemin_apk = os.path.join(dossier_temp, 'apk', 'afriflotte-latest.apk')
            with open(chemin_apk, 'wb') as f:
                f.write(b'faux-contenu-apk')

            with override_settings(MEDIA_ROOT=dossier_temp):
                response = self.client.get('/')

            self.assertContains(response, '/media/apk/afriflotte-latest.apk')
            self.assertNotContains(response, 'Bientôt disponible')
        finally:
            shutil.rmtree(dossier_temp)

    def test_boutons_pointent_vers_lapp_flutter(self):
        with override_settings(FLUTTER_APP_URL='/app/'):
            response = self.client.get('/')

        self.assertContains(response, 'href="/app/"')
