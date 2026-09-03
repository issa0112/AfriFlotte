/// Un ping GPS historisé pour un camion de mission, tel que renvoyé par
/// `PositionGPSSerializer` (`POST /api/tracking/`, `GET .../historique/`).
class PositionGps {
  final int id;
  final int missionCamionId;
  final double latitude;
  final double longitude;
  final double? vitesse;
  final double? precision;
  final DateTime? date;
  final String source;

  const PositionGps({
    required this.id,
    required this.missionCamionId,
    required this.latitude,
    required this.longitude,
    this.vitesse,
    this.precision,
    this.date,
    required this.source,
  });

  factory PositionGps.fromJson(Map<String, dynamic> json) {
    return PositionGps(
      id: _asInt(json['id']) ?? 0,
      missionCamionId: _asInt(json['mission_camion']) ?? 0,
      latitude: _asDouble(json['latitude']) ?? 0,
      longitude: _asDouble(json['longitude']) ?? 0,
      vitesse: _asDouble(json['vitesse']),
      precision: _asDouble(json['precision']),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      source: json['source']?.toString() ?? 'GPS',
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
}
