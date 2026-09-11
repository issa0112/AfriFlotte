import 'camion.dart' show CamionImage;

/// Un camion (et éventuellement un chauffeur) proposé pour une demande,
/// tel que renvoyé par `/api/propositions/` (voir `PropositionCamionSerializer`).
class PropositionCamionInfo {
  final int camionId;
  final String camionImmatriculation;
  final List<CamionImage> camionImages;
  final int? chauffeurId;
  final String? chauffeurNom;
  final String? chauffeurPhoto;

  const PropositionCamionInfo({
    required this.camionId,
    required this.camionImmatriculation,
    this.camionImages = const [],
    this.chauffeurId,
    this.chauffeurNom,
    this.chauffeurPhoto,
  });

  /// Photo à afficher en miniature : celle marquée `principale`, sinon la
  /// première — même résolution que `Camion.imagePrincipaleUrl`.
  CamionImage? get imagePrincipale {
    if (camionImages.isEmpty) return null;
    final principale = camionImages.where((image) => image.principale);
    return principale.isNotEmpty ? principale.first : camionImages.first;
  }

  factory PropositionCamionInfo.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['camion_images'];

    return PropositionCamionInfo(
      camionId: json['camion'] is int
          ? json['camion'] as int
          : int.parse('${json['camion']}'),
      camionImmatriculation: json['camion_immatriculation']?.toString() ?? '',
      camionImages: imagesJson is List
          ? imagesJson
                .whereType<Map<String, dynamic>>()
                .map(CamionImage.fromJson)
                .toList()
          : const [],
      chauffeurId: json['chauffeur'] == null
          ? null
          : (json['chauffeur'] is int
                ? json['chauffeur'] as int
                : int.tryParse('${json['chauffeur']}')),
      chauffeurNom: json['chauffeur_nom']?.toString(),
      chauffeurPhoto: json['chauffeur_photo']?.toString(),
    );
  }
}

class Proposition {
  final int id;
  final int demandeId;
  final String depart;
  final String destination;
  final String typeCamion;
  final String transporteurNom;
  final double prix;
  final String? message;
  final DateTime? delaiDepart;
  final String statut;
  final List<PropositionCamionInfo> camions;
  final DateTime? createdAt;
  final String paysDepart;
  final String paysArrivee;
  final String? devise;

  const Proposition({
    required this.id,
    required this.demandeId,
    required this.depart,
    required this.destination,
    required this.typeCamion,
    required this.transporteurNom,
    required this.prix,
    this.message,
    this.delaiDepart,
    required this.statut,
    required this.camions,
    this.createdAt,
    this.paysDepart = 'ML',
    this.paysArrivee = 'ML',
    this.devise,
  });

  factory Proposition.fromJson(Map<String, dynamic> json) {
    final camionsJson = json['camions'];

    return Proposition(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      demandeId: json['demande'] is int
          ? json['demande'] as int
          : int.parse('${json['demande']}'),
      depart: json['depart']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      typeCamion: json['type_camion']?.toString() ?? '',
      transporteurNom: json['transporteur_nom']?.toString() ?? 'Transporteur',
      prix: double.tryParse('${json['prix']}') ?? 0,
      message: json['message']?.toString(),
      delaiDepart: json['delai_depart'] != null
          ? DateTime.tryParse(json['delai_depart'].toString())
          : null,
      statut: json['statut']?.toString() ?? 'EN_ATTENTE',
      camions: camionsJson is List
          ? camionsJson
                .whereType<Map<String, dynamic>>()
                .map(PropositionCamionInfo.fromJson)
                .toList()
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      paysDepart: json['pays_depart']?.toString() ?? 'ML',
      paysArrivee: json['pays_arrivee']?.toString() ?? 'ML',
      devise: json['devise']?.toString(),
    );
  }

  String get trajet => '$depart → $destination';

  String get statutLibelle {
    switch (statut) {
      case 'ACCEPTEE':
        return 'Acceptée';
      case 'REFUSEE':
        return 'Refusée';
      case 'ANNULEE':
        return 'Annulée';
      default:
        return 'En attente';
    }
  }
}

/// Une ligne camion (+ chauffeur optionnel) à envoyer lors de la création
/// d'une proposition.
class PropositionCamionEntree {
  final int camionId;
  final int? chauffeurId;

  const PropositionCamionEntree({required this.camionId, this.chauffeurId});

  Map<String, dynamic> toJson(int ordre) => {
    'camion': camionId,
    if (chauffeurId != null) 'chauffeur': chauffeurId,
    'ordre': ordre,
  };
}
