import '../l10n/generated/app_localizations.dart';

/// Référentiel partagé des formats/gabarits de camion — précision
/// supplémentaire par rapport au type seul (ex. "40 pieds" pour un
/// porte-conteneur, "20 000 L" pour une citerne), pour un matching
/// demande<->camion plus fin.
///
/// Miroir Django : core/constants.py (FORMAT_CAMION_CHOICES/
/// FORMATS_PAR_TYPE) et core/serializers.py (`valider_format_camion`) —
/// toute modification ici doit être reportée là-bas à la main.
const List<String> formatsCamion = [
  '20_PIEDS',
  '40_PIEDS',
  '20_40_PIEDS',
  '45_PIEDS',
  'CITERNE_10000L',
  'CITERNE_15000L',
  'CITERNE_20000L',
  'CITERNE_25000L',
  'CITERNE_30000L',
  'CITERNE_35000L',
  'CITERNE_40000L',
  'CITERNE_43000L',
  'CITERNE_45000L',
  'CITERNE_50000L',
  'BENNE_4X2',
  'BENNE_6X4',
  'BENNE_8X4',
  'AUTRE',
];

/// Formats valides pour un type de camion donné (PORTE_ENGIN n'a aucun
/// format standard : liste vide, le champ Format ne doit pas être proposé
/// du tout pour lui plutôt que d'imposer un "Autre" inutile).
///
/// Classes de citerne et configurations d'essieux de benne fournies par
/// l'utilisateur (terrain) — cf. core/constants.py pour la source.
List<String> formatsPourType(String typeCamion) {
  switch (typeCamion) {
    case 'PLATEAU':
    case 'CONTENEUR':
      return const ['20_PIEDS', '40_PIEDS', '20_40_PIEDS', '45_PIEDS', 'AUTRE'];
    case 'CITERNE':
      return const [
        'CITERNE_10000L',
        'CITERNE_15000L',
        'CITERNE_20000L',
        'CITERNE_25000L',
        'CITERNE_30000L',
        'CITERNE_35000L',
        'CITERNE_40000L',
        'CITERNE_43000L',
        'CITERNE_45000L',
        'CITERNE_50000L',
        'AUTRE',
      ];
    case 'BENNE':
      return const ['BENNE_4X2', 'BENNE_6X4', 'BENNE_8X4', 'AUTRE'];
    default:
      return const [];
  }
}

/// Capacité (litres) qu'un format de citerne impose — le serveur écrase de
/// toute façon `capacite` avec cette valeur (`CamionSerializer.validate`),
/// donc autant pré-remplir/verrouiller le champ côté app plutôt que de
/// laisser saisir une valeur qui sera silencieusement ignorée à l'envoi.
const Map<String, int> capacitePourFormatCiterne = {
  'CITERNE_10000L': 10000,
  'CITERNE_15000L': 15000,
  'CITERNE_20000L': 20000,
  'CITERNE_25000L': 25000,
  'CITERNE_30000L': 30000,
  'CITERNE_35000L': 35000,
  'CITERNE_40000L': 40000,
  'CITERNE_43000L': 43000,
  'CITERNE_45000L': 45000,
  'CITERNE_50000L': 50000,
};

/// Nombre d'essieux qu'une configuration de benne impose — même logique que
/// [capacitePourFormatCiterne], côté `essieux` au lieu de `capacite`.
const Map<String, int> essieuxPourFormatBenne = {
  'BENNE_4X2': 2,
  'BENNE_6X4': 3,
  'BENNE_8X4': 4,
};

/// Libellé lisible et traduit pour un code de format technique. Même
/// signature que `libelleTypeCamion`/`libelleFraicheur` — nécessite
/// `context` pour la traduction.
String libelleFormatCamion(AppLocalizations l10n, String formatCamion) {
  switch (formatCamion) {
    case '20_PIEDS':
      return l10n.formatCamion20Pieds;
    case '40_PIEDS':
      return l10n.formatCamion40Pieds;
    case '20_40_PIEDS':
      return l10n.formatCamion2040Pieds;
    case '45_PIEDS':
      return l10n.formatCamion45Pieds;
    case 'CITERNE_10000L':
      return l10n.formatCamionCiterne10000L;
    case 'CITERNE_15000L':
      return l10n.formatCamionCiterne15000L;
    case 'CITERNE_20000L':
      return l10n.formatCamionCiterne20000L;
    case 'CITERNE_25000L':
      return l10n.formatCamionCiterne25000L;
    case 'CITERNE_30000L':
      return l10n.formatCamionCiterne30000L;
    case 'CITERNE_35000L':
      return l10n.formatCamionCiterne35000L;
    case 'CITERNE_40000L':
      return l10n.formatCamionCiterne40000L;
    case 'CITERNE_43000L':
      return l10n.formatCamionCiterne43000L;
    case 'CITERNE_45000L':
      return l10n.formatCamionCiterne45000L;
    case 'CITERNE_50000L':
      return l10n.formatCamionCiterne50000L;
    case 'BENNE_4X2':
      return l10n.formatCamionBenne4x2;
    case 'BENNE_6X4':
      return l10n.formatCamionBenne6x4;
    case 'BENNE_8X4':
      return l10n.formatCamionBenne8x4;
    case 'AUTRE':
      return l10n.formatCamionAutre;
    default:
      return formatCamion;
  }
}
