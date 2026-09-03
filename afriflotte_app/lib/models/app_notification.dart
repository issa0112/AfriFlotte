/// Notification interne (nommée `AppNotification` pour ne pas entrer en
/// conflit avec `Notification` de `package:flutter/widgets.dart`).
class AppNotification {
  final int id;
  final String type;
  final String typeLibelle;
  final String message;
  final bool lue;
  final DateTime? createdAt;

  // Lien vivant vers la Proposition concernée (types NOUVELLE_PROPOSITION /
  // PROPOSITION_ACCEPTEE / PROPOSITION_REFUSEE) — `message` est un texte
  // figé au moment de la création, ces champs viennent de la proposition
  // telle qu'elle existe (ou plus) aujourd'hui. `propositionId == null`
  // signifie que la proposition a depuis été supprimée : ne pas se fier au
  // prix mentionné dans `message` dans ce cas.
  final int? propositionId;
  final double? propositionPrix;
  final String? propositionDevise;
  final String? propositionStatut;

  const AppNotification({
    required this.id,
    required this.type,
    required this.typeLibelle,
    required this.message,
    required this.lue,
    this.createdAt,
    this.propositionId,
    this.propositionPrix,
    this.propositionDevise,
    this.propositionStatut,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      type: json['type_notification']?.toString() ?? '',
      typeLibelle: json['type_notification_libelle']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      lue: json['lue'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      propositionId: json['proposition'] == null
          ? null
          : (json['proposition'] is int
                ? json['proposition'] as int
                : int.tryParse('${json['proposition']}')),
      propositionPrix: json['proposition_prix'] == null
          ? null
          : double.tryParse('${json['proposition_prix']}'),
      propositionDevise: json['proposition_devise']?.toString(),
      propositionStatut: json['proposition_statut']?.toString(),
    );
  }
}
