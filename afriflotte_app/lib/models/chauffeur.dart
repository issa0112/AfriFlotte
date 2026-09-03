/// Camion actuellement conduit par un chauffeur (version allégée, dérivée
/// de l'historique d'affectations côté Django : jamais envoyée par le client).
class ChauffeurCamionActuel {
  final int id;
  final String immatriculation;
  final String typeCamion;
  final String marque;
  final String modele;

  const ChauffeurCamionActuel({
    required this.id,
    required this.immatriculation,
    required this.typeCamion,
    required this.marque,
    required this.modele,
  });

  factory ChauffeurCamionActuel.fromJson(Map<String, dynamic> json) {
    return ChauffeurCamionActuel(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      immatriculation: json['immatriculation']?.toString() ?? '',
      typeCamion: json['type_camion']?.toString() ?? '',
      marque: json['marque']?.toString() ?? '',
      modele: json['modele']?.toString() ?? '',
    );
  }
}

class Chauffeur {
  final int id;
  final String nom;
  final String telephone;
  final String numeroPermis;
  final DateTime? dateExpirationPermis;
  final String codeAcces;
  final String? photo;
  final bool disponible;
  final bool actif;
  final String pays;
  final ChauffeurCamionActuel? camionActuel;
  final String? transporteurNom;

  const Chauffeur({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.numeroPermis,
    this.dateExpirationPermis,
    required this.codeAcces,
    this.photo,
    required this.disponible,
    required this.actif,
    this.pays = 'ML',
    this.camionActuel,
    this.transporteurNom,
  });

  bool get aUnCamion => camionActuel != null;

  factory Chauffeur.fromJson(Map<String, dynamic> json) {
    final camionJson = json['camion_actuel'];

    return Chauffeur(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      nom: json['nom']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      numeroPermis: json['numero_permis']?.toString() ?? '',
      dateExpirationPermis: json['date_expiration_permis'] != null
          ? DateTime.tryParse(json['date_expiration_permis'].toString())
          : null,
      codeAcces: json['code_acces']?.toString() ?? '',
      photo: json['photo']?.toString(),
      disponible: json['disponible'] ?? true,
      actif: json['actif'] ?? true,
      pays: json['pays']?.toString() ?? 'ML',
      camionActuel: camionJson is Map<String, dynamic>
          ? ChauffeurCamionActuel.fromJson(camionJson)
          : null,
      transporteurNom: json['transporteur_nom']?.toString(),
    );
  }
}

/// Une ligne d'historique camion ↔ chauffeur (`/api/affectations/`).
class Affectation {
  final int id;
  final int chauffeurId;
  final String chauffeurNom;
  final int camionId;
  final String camionImmatriculation;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String commentaire;
  final bool active;

  const Affectation({
    required this.id,
    required this.chauffeurId,
    required this.chauffeurNom,
    required this.camionId,
    required this.camionImmatriculation,
    this.dateDebut,
    this.dateFin,
    required this.commentaire,
    required this.active,
  });

  factory Affectation.fromJson(Map<String, dynamic> json) {
    return Affectation(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      chauffeurId: json['chauffeur'] is int
          ? json['chauffeur'] as int
          : int.parse('${json['chauffeur']}'),
      chauffeurNom: json['chauffeur_nom']?.toString() ?? '',
      camionId: json['camion'] is int
          ? json['camion'] as int
          : int.parse('${json['camion']}'),
      camionImmatriculation: json['camion_immatriculation']?.toString() ?? '',
      dateDebut: json['date_debut'] != null
          ? DateTime.tryParse(json['date_debut'].toString())
          : null,
      dateFin: json['date_fin'] != null
          ? DateTime.tryParse(json['date_fin'].toString())
          : null,
      commentaire: json['commentaire']?.toString() ?? '',
      active: json['active'] ?? false,
    );
  }
}
