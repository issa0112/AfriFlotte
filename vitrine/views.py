"""Vue(s) du site vitrine public — servi à la racine du domaine, séparé de
l'API (`core/`) et de l'app Flutter Web (voir `settings.FLUTTER_APP_URL`).

Page statique côté contenu (pas de base de données) mais quelques éléments
dynamiques légers : disponibilité de l'APK, année courante pour le pied de
page."""

import json
import os
from datetime import date

from django.conf import settings
from django.shortcuts import render
from django.utils.safestring import mark_safe

from core.constants import PAYS_CEDEAO
from vitrine.traductions import TEXTES, resoudre_langue

APK_NOM_FICHIER = "afriflotte-latest.apk"


def landing(request):
    """Page d'accueil publique. Le bouton de téléchargement APK ne pointe
    vers un fichier réel que s'il existe déjà sous `media/apk/` — pas de lien
    factice tant qu'aucune version n'a été déposée (cf. plan validé).

    Bilingue FR/EN sans le framework i18n de Django (gettext/`compilemessages`
    exige des outils GNU gettext absents de cette machine) : `resoudre_langue`
    lit `?lang=`/le cookie, `TEXTES[langue]` fournit les chaînes au template."""
    chemin_apk = os.path.join(settings.MEDIA_ROOT, "apk", APK_NOM_FICHIER)
    apk_disponible = os.path.isfile(chemin_apk)
    noms_pays = [nom for _code, nom, _devise, _indicatif in PAYS_CEDEAO]

    langue, langue_a_memoriser = resoudre_langue(request)
    t = TEXTES[langue]

    donnees_structurees = {
        "@context": "https://schema.org",
        "@type": "Organization",
        "name": "AfriFlotte",
        "description": t["jsonld_description"],
        "areaServed": noms_pays,
    }

    contexte = {
        "flutter_app_url": settings.FLUTTER_APP_URL,
        "apk_disponible": apk_disponible,
        "apk_url": f"{settings.MEDIA_URL}apk/{APK_NOM_FICHIER}",
        "apk_version": os.environ.get("APK_VERSION", ""),
        "pays_cedeao": noms_pays,
        "annee_courante": date.today().year,
        "donnees_structurees": mark_safe(json.dumps(donnees_structurees, ensure_ascii=False)),
        "langue": langue,
        "t": t,
    }
    reponse = render(request, "vitrine/landing.html", contexte)
    if langue_a_memoriser:
        reponse.set_cookie(
            "afriflotte_lang", langue_a_memoriser, max_age=60 * 60 * 24 * 365
        )
    return reponse
