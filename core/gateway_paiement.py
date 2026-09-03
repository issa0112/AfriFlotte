"""Passerelle de paiement carte bancaire — indépendante du prestataire (PSP).

Deux adaptateurs existent : `SimulateurGatewayAdapter` (par défaut, aucun
appel réseau, réussite immédiate — sert au développement/à la démo) et
`PayDunyaGatewayAdapter` (le vrai prestataire, couvre Mali/Sénégal/Côte
d'Ivoire/Bénin/Burkina Faso/Togo). Basculer de l'un à l'autre = changer
`settings.PAIEMENT_GATEWAY`, rien d'autre à toucher dans le reste du module
paiement (`core/services.py`, `core/views.py`).

Le simulateur utilise un formulaire de carte natif intégré à l'app (le
numéro/CVV ne quittent jamais l'appareil, cf. `POST
/paiements/<id>/confirmer-carte/`). PayDunya, lui, fonctionne par **page de
paiement hébergée** : c'est PayDunya qui affiche le formulaire carte et gère
la conformité PCI, pas nous — `creer_transaction` renvoie alors une
`checkout_url` que le client doit ouvrir (dans une WebView intégrée à l'app
côté Flutter, pas un navigateur externe). `verifier_authenticite_webhook`
existe parce que chaque PSP authentifie ses notifications différemment
(PayDunya envoie un hash dans le payload plutôt qu'un header de signature) —
en faire une méthode d'adaptateur évite d'introduire du code spécifique PSP
dans la vue webhook, qui doit rester agnostique.
"""

import hashlib
import logging
import uuid

import requests
from django.conf import settings

logger = logging.getLogger(__name__)


class GatewayPaiement:
    """Interface commune à tout adaptateur de paiement carte."""

    def creer_transaction(self, paiement):
        """Initialise une transaction pour ce `Paiement`.

        Retourne {"reference": str, "checkout_url": str | None} —
        `checkout_url` est présent pour un prestataire à page hébergée,
        absent pour un flux à formulaire natif intégré (simulateur).
        """
        raise NotImplementedError

    def verifier_transaction(self, reference):
        """Interroge le PSP sur l'état d'une transaction.

        Retourne "REUSSI", "ECHEC" ou "EN_ATTENTE".
        """
        raise NotImplementedError

    def rembourser_transaction(self, reference, montant):
        """Demande un remboursement au PSP. Retourne True/False."""
        raise NotImplementedError

    def verifier_authenticite_webhook(self, payload):
        """Vérifie qu'une notification webhook provient bien du PSP (pas
        d'un tiers qui devine l'URL). `payload` est le corps de la requête
        déjà parsé (dict). Retourne True/False."""
        raise NotImplementedError


class SimulateurGatewayAdapter(GatewayPaiement):
    """Adaptateur par défaut : aucun appel réseau, réussite immédiate.

    Sert à valider tout le flux (modèles, statuts, notifications, écrans
    Flutter) avant qu'un vrai compte marchand n'existe.
    """

    def creer_transaction(self, paiement):
        reference = f"SIM-{uuid.uuid4().hex[:16].upper()}"
        return {"reference": reference, "checkout_url": None}

    def verifier_transaction(self, reference):
        return "REUSSI"

    def rembourser_transaction(self, reference, montant):
        return True

    def verifier_authenticite_webhook(self, payload):
        return True


class PayDunyaInvalide(Exception):
    """Réponse inattendue/en erreur de l'API PayDunya."""


class PayDunyaGatewayAdapter(GatewayPaiement):
    """Prestataire réel — Mali, Sénégal, Côte d'Ivoire, Bénin, Burkina Faso,
    Togo. Doc HTTP/JSON : developers.paydunya.com/doc/EN/http_json (accès
    direct bloqué par leur Cloudflare aux requêtes automatisées — comportement
    recoupé via leurs SDK PHP/Python officiels open-source).

    Le format exact de la notification IPN (webhook) n'est pas garanti à
    100% par la documentation disponible (POST en
    application/x-www-form-urlencoded, avec une clé `data` imbriquée) : le
    parsing dans `core/views.py:paiement_webhook` journalise systématiquement
    la requête brute pour ajustement si le format réel diffère de ce qui est
    géré ici.

    PayDunya n'expose aucune API de remboursement liée à la transaction
    d'origine (seulement un décaissement générique non rattaché) —
    `rembourser_transaction` renvoie donc toujours False, cf.
    `core/services.py:rembourser_paiement_service`.
    """

    _TIMEOUT = 20

    def _base_url(self):
        prefixe = "sandbox-api" if settings.PAYDUNYA_MODE != "live" else "api"
        return f"https://app.paydunya.com/{prefixe}/v1"

    def _headers(self):
        return {
            "Content-Type": "application/json",
            "PAYDUNYA-MASTER-KEY": settings.PAYDUNYA_MASTER_KEY,
            "PAYDUNYA-PRIVATE-KEY": settings.PAYDUNYA_PRIVATE_KEY,
            "PAYDUNYA-TOKEN": settings.PAYDUNYA_TOKEN,
        }

    def creer_transaction(self, paiement):
        base_retour = settings.PAIEMENT_RETOUR_BASE_URL.rstrip("/")
        corps = {
            "invoice": {
                "total_amount": float(paiement.montant_total),
                "description": f"Mission AfriFlotte #{paiement.mission_id}",
            },
            "store": {"name": "AfriFlotte"},
            "actions": {
                "callback_url": f"{base_retour}/api/paiements/webhook/",
                "return_url": f"{base_retour}/api/paiements/retour/",
                "cancel_url": f"{base_retour}/api/paiements/annule/",
            },
            "custom_data": {"paiement_id": paiement.id},
        }

        reponse = requests.post(
            f"{self._base_url()}/checkout-invoice/create",
            json=corps,
            headers=self._headers(),
            timeout=self._TIMEOUT,
        )
        donnees = reponse.json()

        if donnees.get("response_code") != "00":
            raise PayDunyaInvalide(
                donnees.get("response_text") or "Échec de création de la transaction PayDunya."
            )

        return {
            "reference": donnees["token"],
            # Le nom de champ PayDunya "response_text" est trompeur : en cas
            # de succès, c'est bien l'URL de la page de paiement hébergée.
            "checkout_url": donnees["response_text"],
        }

    def verifier_transaction(self, reference):
        try:
            reponse = requests.get(
                f"{self._base_url()}/checkout-invoice/confirm/{reference}",
                headers=self._headers(),
                timeout=self._TIMEOUT,
            )
            statut = reponse.json().get("status")
        except (requests.RequestException, ValueError) as exc:
            # Panne réseau/réponse malformée : ne jamais faire échouer à tort
            # un paiement réel sur un problème transitoire de notre côté.
            logger.warning("PayDunya verifier_transaction indisponible pour %s : %s", reference, exc)
            return "EN_ATTENTE"

        if statut == "completed":
            return "REUSSI"
        if statut in ("failed", "cancelled"):
            return "ECHEC"
        return "EN_ATTENTE"

    def rembourser_transaction(self, reference, montant):
        return False

    def verifier_authenticite_webhook(self, payload):
        hash_recu = payload.get("hash", "")
        hash_attendu = hashlib.sha512(settings.PAYDUNYA_MASTER_KEY.encode()).hexdigest()
        return bool(hash_recu) and hash_recu == hash_attendu


_ADAPTATEURS = {
    "simulateur": SimulateurGatewayAdapter,
    "paydunya": PayDunyaGatewayAdapter,
}


def get_gateway():
    """Retourne l'instance d'adaptateur configurée par `settings.PAIEMENT_GATEWAY`."""
    nom = getattr(settings, "PAIEMENT_GATEWAY", "simulateur")
    adaptateur = _ADAPTATEURS.get(nom, SimulateurGatewayAdapter)
    return adaptateur()
