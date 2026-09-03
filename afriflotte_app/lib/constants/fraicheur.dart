import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Couleurs pour la fraîcheur d'une position résolue (`classifier_fraicheur`
/// côté Django, cf. core/services.py) — partagées entre tout écran qui
/// affiche une position de camion/chauffeur (recherche de camions, flotte du
/// transporteur...). Les libellés passent par `libelleFraicheur` (nécessite
/// `context` pour la traduction), pas par une const map comme les couleurs.
const Map<String, Color> fraicheurCouleurs = {
  'TRES_FIABLE': Color(0xFF16A34A),
  'FIABLE': Color(0xFF0EA5E9),
  'A_VERIFIER': Color(0xFFF59E0B),
  'ANCIENNE': Color(0xFF64748B),
  'INCONNUE': Color(0xFF94A3B8),
};

String libelleFraicheur(AppLocalizations l10n, String? fraicheur) {
  switch (fraicheur) {
    case 'TRES_FIABLE':
      return l10n.fraicheurTresFiable;
    case 'FIABLE':
      return l10n.fraicheurFiable;
    case 'A_VERIFIER':
      return l10n.fraicheurAVerifier;
    case 'ANCIENNE':
      return l10n.fraicheurAncienne;
    default:
      return l10n.fraicheurInconnue;
  }
}

Color couleurFraicheur(String? fraicheur) =>
    fraicheurCouleurs[fraicheur] ?? fraicheurCouleurs['INCONNUE']!;
