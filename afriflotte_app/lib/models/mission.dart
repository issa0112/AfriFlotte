/// Un camion (et éventuellement un chauffeur) affecté à une mission, tel que
/// renvoyé par `MissionCamionSerializer` dans le champ `camions` de `Mission`.
class MissionCamionInfo {
  final int id;
  final int camionId;
  final String camionImmatriculation;
  final int? chauffeurId;
  final String statut;
  final String statutLibelle;

  const MissionCamionInfo({
    required this.id,
    required this.camionId,
    required this.camionImmatriculation,
    this.chauffeurId,
    required this.statut,
    required this.statutLibelle,
  });

  factory MissionCamionInfo.fromJson(Map<String, dynamic> json) {
    return MissionCamionInfo(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      camionId: json['camion'] is int
          ? json['camion'] as int
          : int.parse('${json['camion']}'),
      camionImmatriculation: json['camion_immatriculation']?.toString() ?? '',
      chauffeurId: json['chauffeur'] == null
          ? null
          : (json['chauffeur'] is int
                ? json['chauffeur'] as int
                : int.tryParse('${json['chauffeur']}')),
      statut: json['statut']?.toString() ?? 'PREVU',
      statutLibelle: json['statut_libelle']?.toString() ?? 'Prévu',
    );
  }

  /// Vrai une fois la livraison faite ou la course annulée : plus rien à
  /// suivre en temps réel pour ce camion.
  bool get estTermine => statut == 'LIVRE' || statut == 'ANNULE';
}

/// Mission côté client : une demande acceptée, confiée à un transporteur.
class Mission {
  final int id;
  final int? demandeId;
  final String depart;
  final String destination;
  final String produit;
  final String typeCamion;
  final String statut;
  final String statutLibelle;
  final String transporteurNom;
  final int nombreCamions;
  final double? prixFinal;
  final DateTime? dateChargement;
  final DateTime? dateCreation;
  final DateTime? dateDepart;
  final DateTime? dateArrivee;
  final List<MissionCamionInfo> camions;
  final String paysDepart;
  final String paysArrivee;
  final String? devise;
  final String? clientNom;

  const Mission({
    required this.id,
    required this.demandeId,
    required this.depart,
    required this.destination,
    required this.produit,
    required this.typeCamion,
    required this.statut,
    required this.statutLibelle,
    required this.transporteurNom,
    required this.nombreCamions,
    required this.prixFinal,
    required this.dateChargement,
    required this.dateCreation,
    required this.dateDepart,
    required this.dateArrivee,
    this.camions = const [],
    this.paysDepart = 'ML',
    this.paysArrivee = 'ML',
    this.devise,
    this.clientNom,
  });

  /// L'API peut renvoyer des champs nuls (description vide, mission pas encore
  /// partie...). On reste tolérant pour ne jamais casser la liste à l'affichage.
  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: _asInt(json['id']) ?? 0,
      demandeId: _asInt(json['demande']),
      depart: _asString(json['depart'], fallback: 'Départ inconnu'),
      destination: _asString(
        json['destination'],
        fallback: 'Destination inconnue',
      ),
      produit: _asString(json['produit'], fallback: 'Marchandise non précisée'),
      typeCamion: _asString(json['type_camion'], fallback: 'Non précisé'),
      statut: _asString(json['statut'], fallback: 'PLANIFIEE'),
      statutLibelle: _asString(
        json['statut_libelle'],
        fallback: _asString(json['statut'], fallback: 'Planifiée'),
      ),
      transporteurNom: _asString(
        json['transporteur_nom'],
        fallback: 'Transporteur non assigné',
      ),
      nombreCamions: _asInt(json['nombre_camions']) ?? 0,
      prixFinal: _asDouble(json['prix_final']),
      dateChargement: _asDate(json['date_chargement']),
      dateCreation: _asDate(json['date_creation']),
      dateDepart: _asDate(json['date_depart']),
      dateArrivee: _asDate(json['date_arrivee']),
      camions: json['camions'] is List
          ? (json['camions'] as List)
                .whereType<Map<String, dynamic>>()
                .map(MissionCamionInfo.fromJson)
                .toList()
          : const [],
      paysDepart: _asString(json['pays_depart'], fallback: 'ML'),
      paysArrivee: _asString(json['pays_arrivee'], fallback: 'ML'),
      devise: json['devise']?.toString(),
      clientNom: json['client_nom']?.toString(),
    );
  }

  bool get estTerminee => statut.toUpperCase() == 'TERMINEE';

  bool get estEnCours => statut.toUpperCase() == 'EN_COURS';

  String get trajet => '$depart → $destination';

  /// Le camion à suivre sur l'écran GPS : le premier non encore livré/annulé,
  /// sinon simplement le premier de la liste.
  MissionCamionInfo? get camionASuivre {
    if (camions.isEmpty) return null;
    return camions.firstWhere(
      (c) => !c.estTermine,
      orElse: () => camions.first,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _asString(dynamic value, {required String fallback}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
