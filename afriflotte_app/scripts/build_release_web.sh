#!/usr/bin/env bash
# Construit le build Flutter Web servi en production sur /app/
# (afriflotte_app/build/web/, suivi en git — cf. .gitignore) et le laisse
# directement à l'endroit d'où afriflotte/urls.py le sert.
#
# Pourquoi ce script existe : /app/ est resté figé sur un build du 3
# septembre pendant deux semaines de travail (contrats, paiement, connexion
# persistante...) simplement parce que personne n'a pensé à relancer
# `flutter build web` — contrairement au backend qui se redéploie tout seul
# à chaque push, ce build compilé doit être reconstruit et commité à la
# main. Un `flutter build web` sans --base-href=/app/ casse le routage (les
# assets se chargent depuis la racine du domaine au lieu de /app/), et sans
# --dart-define=API_BASE_URL retombe sur l'URL de développement local —
# exactement le bug vécu le 2026-09-18 sur l'inscription transporteur.
#
# Usage : ./scripts/build_release_web.sh [url-api]
# Par défaut, url-api = https://web-production-2d2d5.up.railway.app/api
# (le même serveur que l'APK, cf. build_release_apk.sh).

set -euo pipefail
cd "$(dirname "$0")/.."

# Évite que Git Bash (MSYS) ne réinterprète "/app/" comme un chemin
# Windows local (ex. "C:/Program Files/Git/app/") — inoffensif ailleurs
# qu'en Git Bash sur Windows, où cette variable n'a aucun effet.
export MSYS_NO_PATHCONV=1

API_BASE_URL="${1:-https://web-production-2d2d5.up.railway.app/api}"

echo "Build Web release avec API_BASE_URL=$API_BASE_URL"
flutter build web --base-href=/app/ \
  --dart-define=API_BASE_URL="$API_BASE_URL"

echo "OK : build/web/ mis à jour."
echo "Il ne reste qu'à commit + push pour republier sur /app/ (build/web/ n'est pas dans .gitignore)."
