class DemandeTransport {
  final int id;
  final String depart;
  final String destination;
  final String produit;
  final String typeCamion;
  final String formatCamion;
  final String formatAutre;
  final int nombreCamions;
  final String statut;
  final double? quantite;
  final String unite;
  final double? prixPropose;
  final DateTime? dateChargement;
  final DateTime? dateCreation;
  final String paysDepart;
  final String paysArrivee;
  final double? latitudeDepart;
  final double? longitudeDepart;
  final double? latitudeArrivee;
  final double? longitudeArrivee;
  final String? devise;
  final String? clientNom;

  const DemandeTransport({
    required this.id,
    required this.depart,
    required this.destination,
    required this.produit,
    required this.typeCamion,
    this.formatCamion = '',
    this.formatAutre = '',
    required this.nombreCamions,
    required this.statut,
    required this.quantite,
    required this.unite,
    required this.prixPropose,
    required this.dateChargement,
    required this.dateCreation,
    this.paysDepart = 'ML',
    this.paysArrivee = 'ML',
    this.latitudeDepart,
    this.longitudeDepart,
    this.latitudeArrivee,
    this.longitudeArrivee,
    this.devise,
    this.clientNom,
  });

  /// `produit` vient de `description`, qui est nullable côté Django, et les
  /// DecimalField arrivent en chaînes. On parse donc défensivement.
  factory DemandeTransport.fromJson(Map<String, dynamic> json) {
    return DemandeTransport(
      id: _asInt(json['id']) ?? 0,
      depart: _asString(
        json['depart'] ?? json['ville_depart'],
        fallback: 'Départ inconnu',
      ),
      destination: _asString(
        json['destination'] ?? json['ville_arrivee'],
        fallback: 'Destination inconnue',
      ),
      produit: _asString(
        json['produit'] ?? json['description'],
        fallback: 'Marchandise non précisée',
      ),
      typeCamion: _asString(json['type_camion'], fallback: 'Non précisé'),
      formatCamion: _asString(json['format_camion'], fallback: ''),
      formatAutre: _asString(json['format_autre'], fallback: ''),
      nombreCamions: _asInt(json['nombre_camions']) ?? 1,
      statut: _asString(json['statut'], fallback: 'OUVERTE'),
      quantite: _asDouble(json['quantite']),
      unite: _asString(json['unite'], fallback: ''),
      prixPropose: _asDouble(json['prix_propose']),
      dateChargement: _asDate(json['date_chargement']),
      dateCreation: _asDate(json['date_creation']),
      paysDepart: _asString(json['pays_depart'], fallback: 'ML'),
      paysArrivee: _asString(json['pays_arrivee'], fallback: 'ML'),
      latitudeDepart: _asDouble(json['latitude_depart']),
      longitudeDepart: _asDouble(json['longitude_depart']),
      latitudeArrivee: _asDouble(json['latitude_arrivee']),
      longitudeArrivee: _asDouble(json['longitude_arrivee']),
      devise: json['devise']?.toString(),
      clientNom: json['client_nom']?.toString(),
    );
  }

  String get trajet => '$depart → $destination';

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
