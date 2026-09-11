#!/usr/bin/env bash
# Construit l'APK Android publié sur le bouton "Télécharger" de la landing
# page et le dépose directement à l'endroit où vitrine/views.py va le
# chercher (media/apk/afriflotte-latest.apk).
#
# Pourquoi ce script existe : un `flutter build apk` sans
# --dart-define=API_BASE_URL retombe sur l'URL de développement local
# (10.0.2.2, cf. lib/services/api_service.dart) — l'app compilée ne peut
# alors plus se connecter/inscrire une fois installée sur un vrai téléphone.
# C'est exactement le bug vécu le 2026-09-11 sur la première publication.
#
# Usage : ./scripts/build_release_apk.sh [url-api]
# Par défaut, url-api = https://web-production-2d2d5.up.railway.app/api
# (le même serveur que le build web déjà déployé sous /app/).

set -euo pipefail
cd "$(dirname "$0")/.."

API_BASE_URL="${1:-https://web-production-2d2d5.up.railway.app/api}"

echo "Build APK release (arm64) avec API_BASE_URL=$API_BASE_URL"
flutter build apk --release --target-platform android-arm64 \
  --dart-define=API_BASE_URL="$API_BASE_URL"

mkdir -p ../media/apk
cp build/app/outputs/flutter-apk/app-release.apk ../media/apk/afriflotte-latest.apk

echo "OK : ../media/apk/afriflotte-latest.apk mis à jour."
echo "Il ne reste qu'à commit + push pour republier (media/apk/*.apk n'est pas dans .gitignore)."
