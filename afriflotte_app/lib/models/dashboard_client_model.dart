import 'revenu_devise.dart';

/// Statistiques du compte ENTREPRISE (client) connecté, renvoyées par
/// `/api/client/dashboard/` (`ClientDashboardSerializer` côté Django) —
/// pendant client de `DashboardTransporteurModel`.
class DashboardClientModel {
  // ==========================
  // DEMANDES
  // ==========================

  final int demandesTotal;
  final int demandesOuvertes;
  final int demandesEnCours;
  final int demandesTerminees;
  final int demandesAnnulees;

  // ==========================
  // MISSIONS
  // ==========================

  final int missionsTotal;
  final int missionsEnCours;
  final int missionsTerminees;

  // ==========================
  // PROPOSITIONS
  // ==========================

  final int propositionsEnAttente;

  // ==========================
  // DEPENSES
  // ==========================
  //
  // Ventilées par devise (dérivée de demande.pays_depart) : un client CEDEAO
  // peut avoir des missions terminées dans plusieurs pays, donc plusieurs
  // devises. Cf. RevenuDevise et revenus_par_devise() côté Django.

  final List<RevenuDevise> depensesTotal;
  final List<RevenuDevise> depensesMois;

  // ==========================
  // NOTIFICATIONS
  // ==========================

  final int notificationsNonLues;

  DashboardClientModel({
    required this.demandesTotal,
    required this.demandesOuvertes,
    required this.demandesEnCours,
    required this.demandesTerminees,
    required this.demandesAnnulees,
    required this.missionsTotal,
    required this.missionsEnCours,
    required this.missionsTerminees,
    required this.propositionsEnAttente,
    required this.depensesTotal,
    required this.depensesMois,
    required this.notificationsNonLues,
  });

  factory DashboardClientModel.fromJson(Map<String, dynamic> json) {
    return DashboardClientModel(
      demandesTotal: json["demandes_total"] ?? 0,
      demandesOuvertes: json["demandes_ouvertes"] ?? 0,
      demandesEnCours: json["demandes_en_cours"] ?? 0,
      demandesTerminees: json["demandes_terminees"] ?? 0,
      demandesAnnulees: json["demandes_annulees"] ?? 0,
      missionsTotal: json["missions_total"] ?? 0,
      missionsEnCours: json["missions_en_cours"] ?? 0,
      missionsTerminees: json["missions_terminees"] ?? 0,
      propositionsEnAttente: json["propositions_en_attente"] ?? 0,
      depensesTotal: revenusParDeviseDepuisJson(json["depenses_total"]),
      depensesMois: revenusParDeviseDepuisJson(json["depenses_mois"]),
      notificationsNonLues: json["notifications_non_lues"] ?? 0,
    );
  }
}
