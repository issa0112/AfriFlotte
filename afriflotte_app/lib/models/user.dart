class User {
  final int id;
  final String nom;
  final String telephone;
  final String role;

  User({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],

      nom: json["username"],

      telephone: json["telephone"] ?? "",

      role: json["type_compte"],
    );
  }
}
