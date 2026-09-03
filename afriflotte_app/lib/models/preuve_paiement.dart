/// Justificatif attaché à un paiement, tel que renvoyé par
/// `PreuvePaiementSerializer` — reçu espèces, signature client, capture PSP,
/// justificatif de virement (versement transporteur) ou de remboursement.
class PreuvePaiement {
  final int id;
  final String fichierUrl;
  final String typePreuve;
  final String typePreuveLibelle;
  final String? commentaire;
  final DateTime? createdAt;

  const PreuvePaiement({
    required this.id,
    required this.fichierUrl,
    required this.typePreuve,
    required this.typePreuveLibelle,
    this.commentaire,
    this.createdAt,
  });

  factory PreuvePaiement.fromJson(Map<String, dynamic> json) {
    return PreuvePaiement(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      fichierUrl: json['fichier']?.toString() ?? '',
      typePreuve: json['type_preuve']?.toString() ?? 'AUTRE',
      typePreuveLibelle: json['type_preuve_libelle']?.toString() ?? '',
      commentaire: json['commentaire']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
