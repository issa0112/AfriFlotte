import 'revenu_devise.dart';

class AdminDashboardModel {
  final int transporteursTotal;
  final int entreprisesTotal;
  final int chauffeursTotal;

  final int camionsTotal;
  final int camionsDisponibles;

  final int missionsTotal;
  final int missionsEnCours;
  final int missionsTerminees;

  final int demandesOuvertes;

  final List<RevenuDevise> revenusTotal;

  const AdminDashboardModel({
    required this.transporteursTotal,
    required this.entreprisesTotal,
    required this.chauffeursTotal,
    required this.camionsTotal,
    required this.camionsDisponibles,
    required this.missionsTotal,
    required this.missionsEnCours,
    required this.missionsTerminees,
    required this.demandesOuvertes,
    required this.revenusTotal,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      transporteursTotal: json['transporteurs_total'] ?? 0,
      entreprisesTotal: json['entreprises_total'] ?? 0,
      chauffeursTotal: json['chauffeurs_total'] ?? 0,
      camionsTotal: json['camions_total'] ?? 0,
      camionsDisponibles: json['camions_disponibles'] ?? 0,
      missionsTotal: json['missions_total'] ?? 0,
      missionsEnCours: json['missions_en_cours'] ?? 0,
      missionsTerminees: json['missions_terminees'] ?? 0,
      demandesOuvertes: json['demandes_ouvertes'] ?? 0,
      revenusTotal: revenusParDeviseDepuisJson(json['revenus_total']),
    );
  }
}
