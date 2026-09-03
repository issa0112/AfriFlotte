import '../l10n/generated/app_localizations.dart';

/// Référentiel partagé des types de camion.
///
/// Miroir Django : core/constants.py (TYPE_CAMION_CHOICES) et
/// core/serializers.py (CamionSerializer.validate, source de vérité pour
/// l'unité de capacité) — toute modification ici doit être reportée là-bas
/// à la main, aucun outillage de génération commune n'existe.
const List<String> typesCamion = [
  'CITERNE',
  'BENNE',
  'PLATEAU',
  'CONTENEUR',
  'PORTE_ENGIN',
];

/// Unité de capacité cohérente avec le type de camion : seule une citerne
/// transporte du liquide (litres), tout le reste se mesure en tonnes. Le
/// serveur réapplique la même règle à l'enregistrement (voir
/// CamionSerializer.validate) — ceci ne sert qu'à préremplir/afficher
/// correctement côté app.
String uniteCapacitePourType(String typeCamion) {
  return typeCamion == 'CITERNE' ? 'litres' : 'tonnes';
}

/// Libellé lisible et traduit pour un type de camion technique (ex.
/// `PORTE_ENGIN` -> `Porte-engin` / `Equipment carrier`). Purement
/// cosmétique, ne touche pas à la valeur stockée. Même signature que
/// `libelleFraicheur` (constants/fraicheur.dart) — nécessite `context` pour
/// la traduction, pas une const map.
String libelleTypeCamion(AppLocalizations l10n, String typeCamion) {
  switch (typeCamion) {
    case 'CITERNE':
      return l10n.typeCamionCiterne;
    case 'BENNE':
      return l10n.typeCamionBenne;
    case 'PLATEAU':
      return l10n.typeCamionPlateau;
    case 'CONTENEUR':
      return l10n.typeCamionConteneur;
    case 'PORTE_ENGIN':
      return l10n.typeCamionPorteEngin;
    default:
      return typeCamion.replaceAll('_', ' ').toLowerCase();
  }
}
