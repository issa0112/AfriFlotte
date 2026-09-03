import 'revenu_devise.dart';

class DashboardTransporteurModel {
  // ==========================
  // CAMIONS
  // ==========================

  final int camionsTotal;
  final int camionsDisponibles;
  final int camionsEnMission;
  final int camionsMaintenance;
  final int camionsHorsService;

  // ==========================
  // CHAUFFEURS
  // ==========================

  final int chauffeursTotal;
  final int chauffeursDisponibles;
  final int chauffeursEnMission;

  // ==========================
  // MISSIONS
  // ==========================

  final int missionsPlanifiees;
  final int missionsEnCours;
  final int missionsTerminees;
  final int missionsAnnulees;
  final int missionsAujourdHui;

  // ==========================
  // DEMANDES
  // ==========================

  final int demandesDisponibles;
  final int propositionsEnAttente;

  // ==========================
  // FINANCES
  // ==========================

  final List<RevenuDevise> revenus;
  final List<RevenuDevise> revenusMois;
  final List<RevenuDevise> revenusAnnee;

  // ==========================
  // NOTIFICATIONS
  // ==========================

  final int notificationsNonLues;

  DashboardTransporteurModel({
    required this.camionsTotal,
    required this.camionsDisponibles,
    required this.camionsEnMission,
    required this.camionsMaintenance,
    required this.camionsHorsService,

    required this.chauffeursTotal,
    required this.chauffeursDisponibles,
    required this.chauffeursEnMission,

    required this.missionsPlanifiees,
    required this.missionsEnCours,
    required this.missionsTerminees,
    required this.missionsAnnulees,
    required this.missionsAujourdHui,

    required this.demandesDisponibles,
    required this.propositionsEnAttente,

    required this.revenus,
    required this.revenusMois,
    required this.revenusAnnee,

    required this.notificationsNonLues,
  });

  factory DashboardTransporteurModel.fromJson(Map<String, dynamic> json) {
    return DashboardTransporteurModel(
      // CAMIONS

      camionsTotal: json["camions_total"] ?? 0,

      camionsDisponibles: json["camions_disponibles"] ?? 0,

      camionsEnMission: json["camions_en_mission"] ?? 0,

      camionsMaintenance: json["camions_maintenance"] ?? 0,

      camionsHorsService: json["camions_hors_service"] ?? 0,

      // CHAUFFEURS
      chauffeursTotal: json["chauffeurs_total"] ?? 0,

      chauffeursDisponibles: json["chauffeurs_disponibles"] ?? 0,

      chauffeursEnMission: json["chauffeurs_en_mission"] ?? 0,

      // MISSIONS
      missionsPlanifiees: json["missions_planifiees"] ?? 0,

      missionsEnCours: json["missions_en_cours"] ?? 0,

      missionsTerminees: json["missions_terminees"] ?? 0,

      missionsAnnulees: json["missions_annulees"] ?? 0,

      missionsAujourdHui: json["missions_aujourdhui"] ?? 0,

      // DEMANDES
      demandesDisponibles: json["demandes_disponibles"] ?? 0,

      propositionsEnAttente: json["propositions_en_attente"] ?? 0,

      // FINANCES
      revenus: revenusParDeviseDepuisJson(json["revenus"]),

      revenusMois: revenusParDeviseDepuisJson(json["revenus_mois"]),

      revenusAnnee: revenusParDeviseDepuisJson(json["revenus_annee"]),

      // NOTIFICATIONS
      notificationsNonLues: json["notifications_non_lues"] ?? 0,
    );
  }
}
