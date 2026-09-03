/// Position résolue d'un camion renvoyée par `/api/recherche-camions/`
/// (voir `resoudre_position_camion` côté Django) : GPS propre du camion,
/// sinon celui du chauffeur affecté, sinon une valeur statique.
class PositionResolue {
  final double latitude;
  final double longitude;
  final String source;
  final DateTime? updatedAt;
  final String fraicheur;

  const PositionResolue({
    required this.latitude,
    required this.longitude,
    required this.source,
    this.updatedAt,
    required this.fraicheur,
  });

  factory PositionResolue.fromJson(Map<String, dynamic> json) {
    return PositionResolue(
      latitude: _asDouble(json['latitude']) ?? 0,
      longitude: _asDouble(json['longitude']) ?? 0,
      source: json['source']?.toString() ?? 'INCONNUE',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      fraicheur: json['fraicheur']?.toString() ?? 'INCONNUE',
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Chauffeur actuellement affecté à un camion, tel que renvoyé par
/// `ChauffeurResumeSerializer` à l'intérieur d'un `CamionFlotteSerializer`.
class ChauffeurResume {
  final int id;
  final String nom;
  final String telephone;
  final String pays;

  const ChauffeurResume({
    required this.id,
    required this.nom,
    required this.telephone,
    this.pays = 'ML',
  });

  factory ChauffeurResume.fromJson(Map<String, dynamic> json) {
    return ChauffeurResume(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      nom: json['nom']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      pays: json['pays']?.toString() ?? 'ML',
    );
  }
}

/// Un camion tel que renvoyé par la recherche par proximité (`CamionSerializer`
/// habituel + `position`/`distance_km`) ou par la flotte du transporteur
/// (idem + `chauffeur_actuel`) — les deux vues partagent la même forme côté
/// Django (`CamionRechercheSerializer`/`CamionFlotteSerializer` en hérite).
class CamionRecherche {
  final int id;
  final String typeCamion;
  final String immatriculation;
  final String marque;
  final String modele;
  final double capacite;
  final String uniteCapacite;
  final bool disponible;
  final String ville;
  final String pays;
  final PositionResolue? position;
  final double? distanceKm;
  final ChauffeurResume? chauffeurActuel;

  const CamionRecherche({
    required this.id,
    required this.typeCamion,
    required this.immatriculation,
    required this.marque,
    required this.modele,
    required this.capacite,
    required this.uniteCapacite,
    required this.disponible,
    required this.ville,
    this.pays = 'ML',
    this.position,
    this.distanceKm,
    this.chauffeurActuel,
  });

  factory CamionRecherche.fromJson(Map<String, dynamic> json) {
    final positionJson = json['position'];
    final chauffeurJson = json['chauffeur_actuel'];

    return CamionRecherche(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      typeCamion: json['type_camion']?.toString() ?? '',
      immatriculation: json['immatriculation']?.toString() ?? '',
      marque: json['marque']?.toString() ?? '',
      modele: json['modele']?.toString() ?? '',
      capacite: double.tryParse(json['capacite'].toString()) ?? 0,
      uniteCapacite: json['unite_capacite']?.toString() ?? 'litres',
      disponible: json['disponible'] ?? true,
      ville: json['ville']?.toString() ?? '',
      pays: json['pays']?.toString() ?? 'ML',
      position: positionJson is Map<String, dynamic>
          ? PositionResolue.fromJson(positionJson)
          : null,
      distanceKm: json['distance_km'] is num
          ? (json['distance_km'] as num).toDouble()
          : double.tryParse('${json['distance_km']}'),
      chauffeurActuel: chauffeurJson is Map<String, dynamic>
          ? ChauffeurResume.fromJson(chauffeurJson)
          : null,
    );
  }
}
