/// Un compte TRANSPORTEUR ou ENTREPRISE tel que renvoyé par
/// `AdminUtilisateursView` (`UserSerializer`) — vue admin plateforme, pas le
/// compte de la session courante (voir `AdminUtilisateursScreen`).
class UtilisateurAdmin {
  final int id;
  final String username;
  final String? nomEntreprise;
  final String telephone;
  final String? email;
  final String? adresse;
  final String pays;
  final String typeCompte;

  const UtilisateurAdmin({
    required this.id,
    required this.username,
    this.nomEntreprise,
    required this.telephone,
    this.email,
    this.adresse,
    this.pays = 'ML',
    required this.typeCompte,
  });

  /// Nom affiché en priorité : la raison sociale si elle est renseignée,
  /// sinon l'identifiant de connexion.
  String get nomAffiche =>
      (nomEntreprise != null && nomEntreprise!.trim().isNotEmpty)
      ? nomEntreprise!
      : username;

  factory UtilisateurAdmin.fromJson(Map<String, dynamic> json) {
    return UtilisateurAdmin(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      username: json['username']?.toString() ?? '',
      nomEntreprise: json['nom_entreprise']?.toString(),
      telephone: json['telephone']?.toString() ?? '',
      email: json['email']?.toString(),
      adresse: json['adresse']?.toString(),
      pays: json['pays']?.toString() ?? 'ML',
      typeCompte: json['type_compte']?.toString() ?? '',
    );
  }
}
