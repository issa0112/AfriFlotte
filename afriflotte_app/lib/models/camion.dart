class CamionImage {
  final int id;
  final String url;
  final bool principale;

  const CamionImage({
    required this.id,
    required this.url,
    required this.principale,
  });

  factory CamionImage.fromJson(Map<String, dynamic> json) {
    return CamionImage(
      id: json["id"] is int ? json["id"] as int : int.parse('${json["id"]}'),
      url: json["image"]?.toString() ?? "",
      principale: json["principale"] ?? false,
    );
  }
}

class Camion {
  final int id;

  final String typeCamion;

  final String formatCamion;

  final String formatAutre;

  final int? essieux;

  final String immatriculation;

  final String marque;

  final String modele;

  final int? annee;

  final double capacite;

  final String uniteCapacite;

  final bool disponible;

  final String ville;

  final String pays;

  final double? latitude;

  final double? longitude;

  final List<CamionImage> images;

  final String? proprietaireNom;

  Camion({
    required this.id,

    required this.typeCamion,

    this.formatCamion = "",

    this.formatAutre = "",

    this.essieux,

    required this.immatriculation,

    required this.marque,

    required this.modele,

    this.annee,

    required this.capacite,

    required this.uniteCapacite,

    required this.disponible,

    required this.ville,

    this.pays = "ML",

    this.latitude,

    this.longitude,

    this.images = const [],

    this.proprietaireNom,
  });

  /// Photo à afficher en priorité : celle marquée `principale`, sinon la
  /// première ajoutée, sinon `null` si le camion n'a aucune photo.
  String? get imagePrincipaleUrl {
    if (images.isEmpty) return null;
    final principale = images.where((image) => image.principale);
    return principale.isNotEmpty ? principale.first.url : images.first.url;
  }

  factory Camion.fromJson(Map<String, dynamic> json) {
    final imagesJson = json["images"];

    return Camion(
      id: json["id"],

      typeCamion: json["type_camion"] ?? "",

      formatCamion: json["format_camion"] ?? "",

      formatAutre: json["format_autre"] ?? "",

      essieux: json["essieux"] is int
          ? json["essieux"] as int
          : int.tryParse('${json["essieux"]}'),

      immatriculation: json["immatriculation"] ?? "",

      marque: json["marque"] ?? "",

      modele: json["modele"] ?? "",

      annee: json["annee"],

      capacite: double.tryParse(json["capacite"].toString()) ?? 0,

      uniteCapacite: json["unite_capacite"] ?? "litres",

      disponible: json["disponible"] ?? true,

      ville: json["ville"] ?? "Bamako",

      pays: json["pays"] ?? "ML",

      latitude: json["latitude"] != null
          ? double.tryParse(json["latitude"].toString())
          : null,

      longitude: json["longitude"] != null
          ? double.tryParse(json["longitude"].toString())
          : null,

      images: imagesJson is List
          ? imagesJson
                .whereType<Map<String, dynamic>>()
                .map(CamionImage.fromJson)
                .toList()
          : const [],

      proprietaireNom: json["proprietaire"]?.toString(),
    );
  }
}
