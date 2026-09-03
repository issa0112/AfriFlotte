/// Litige ouvert sur un paiement (`LitigeSerializer` côté Django).
class Litige {
  final int id;
  final int paiementId;
  final int? ouvertPar;
  final String? ouvertParNom;
  final String motif;
  final String statut;
  final String statutLibelle;
  final String? resolutionCommentaire;
  final DateTime? createdAt;
  final DateTime? resoluAt;

  const Litige({
    required this.id,
    required this.paiementId,
    this.ouvertPar,
    this.ouvertParNom,
    required this.motif,
    required this.statut,
    required this.statutLibelle,
    this.resolutionCommentaire,
    this.createdAt,
    this.resoluAt,
  });

  factory Litige.fromJson(Map<String, dynamic> json) {
    return Litige(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      paiementId: json['paiement'] is int
          ? json['paiement'] as int
          : int.parse('${json['paiement']}'),
      ouvertPar: json['ouvert_par'] is int ? json['ouvert_par'] as int : null,
      ouvertParNom: json['ouvert_par_nom']?.toString(),
      motif: json['motif']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'OUVERT',
      statutLibelle: json['statut_libelle']?.toString() ?? '',
      resolutionCommentaire: json['resolution_commentaire']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      resoluAt: json['resolu_at'] != null
          ? DateTime.tryParse(json['resolu_at'].toString())
          : null,
    );
  }

  bool get estOuvert => statut == 'OUVERT' || statut == 'EN_EXAMEN';
}
