import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/models/dashboard_transporteur_model.dart';
import 'package:afriflotte_app/models/admin_dashboard_model.dart';
import 'package:afriflotte_app/models/dashboard_client_model.dart';

void main() {
  group('DashboardTransporteurModel.fromJson', () {
    test('parses all sections of the transporteur dashboard', () {
      final dashboard = DashboardTransporteurModel.fromJson({
        'camions_total': 5,
        'camions_disponibles': 3,
        'camions_en_mission': 2,
        'camions_maintenance': 0,
        'camions_hors_service': 0,
        'chauffeurs_total': 4,
        'chauffeurs_disponibles': 2,
        'chauffeurs_en_mission': 2,
        'missions_planifiees': 1,
        'missions_en_cours': 2,
        'missions_terminees': 10,
        'missions_annulees': 1,
        'missions_aujourdhui': 1,
        'demandes_disponibles': 6,
        'propositions_en_attente': 2,
        // Ventilé par devise depuis le passage au périmètre CEDEAO : plus un
        // nombre unique, une liste {devise, montant} (cf. revenus_par_devise
        // dans core/services.py).
        'revenus': [
          {'devise': 'XOF', 'montant': 500000},
          {'devise': 'GHS', 'montant': 80000},
        ],
        'revenus_mois': [
          {'devise': 'XOF', 'montant': 150000},
        ],
        'revenus_annee': [
          {'devise': 'XOF', 'montant': 2000000},
        ],
        'notifications_non_lues': 3,
      });

      expect(dashboard.camionsTotal, 5);
      expect(dashboard.chauffeursDisponibles, 2);
      expect(dashboard.missionsEnCours, 2);
      expect(dashboard.revenus.length, 2);
      expect(dashboard.revenus[0].devise, 'XOF');
      expect(dashboard.revenus[0].montant, 500000.0);
      expect(dashboard.revenus[1].devise, 'GHS');
      expect(dashboard.revenus[1].montant, 80000.0);
      expect(dashboard.revenusMois.single.montant, 150000.0);
      expect(dashboard.revenusAnnee.single.montant, 2000000.0);
      expect(dashboard.notificationsNonLues, 3);
    });

    test('defaults every field to 0/empty when the payload is empty', () {
      final dashboard = DashboardTransporteurModel.fromJson({});

      expect(dashboard.camionsTotal, 0);
      expect(dashboard.revenus, isEmpty);
      expect(dashboard.notificationsNonLues, 0);
    });
  });

  group('AdminDashboardModel.fromJson', () {
    test('parses global platform statistics', () {
      final dashboard = AdminDashboardModel.fromJson({
        'transporteurs_total': 7,
        'entreprises_total': 3,
        'chauffeurs_total': 5,
        'camions_total': 12,
        'camions_disponibles': 8,
        'missions_total': 20,
        'missions_en_cours': 4,
        'missions_terminees': 15,
        'demandes_ouvertes': 6,
        'revenus_total': [
          {'devise': 'XOF', 'montant': 4500000},
          {'devise': 'NGN', 'montant': 30000},
        ],
      });

      expect(dashboard.transporteursTotal, 7);
      expect(dashboard.camionsDisponibles, 8);
      expect(dashboard.revenusTotal.length, 2);
      expect(dashboard.revenusTotal[0].devise, 'XOF');
      expect(dashboard.revenusTotal[0].montant, 4500000.0);
      expect(dashboard.revenusTotal[1].devise, 'NGN');
      expect(dashboard.revenusTotal[1].montant, 30000.0);
    });

    test('defaults every field to 0/empty when the payload is empty', () {
      final dashboard = AdminDashboardModel.fromJson({});

      expect(dashboard.transporteursTotal, 0);
      expect(dashboard.revenusTotal, isEmpty);
    });
  });

  group('DashboardClientModel.fromJson', () {
    test('parses all sections of the client dashboard', () {
      final dashboard = DashboardClientModel.fromJson({
        'demandes_total': 4,
        'demandes_ouvertes': 1,
        'demandes_en_cours': 1,
        'demandes_terminees': 2,
        'demandes_annulees': 0,
        'missions_total': 2,
        'missions_en_cours': 1,
        'missions_terminees': 1,
        'propositions_en_attente': 1,
        // Ventilées par devise depuis le passage au périmètre CEDEAO : plus
        // un nombre unique, une liste {devise, montant} (cf.
        // revenus_par_devise dans core/services.py), même pattern que
        // DashboardTransporteurModel.revenus.
        'depenses_total': [
          {'devise': 'XOF', 'montant': 200000},
          {'devise': 'GHS', 'montant': 45000},
        ],
        'depenses_mois': [
          {'devise': 'XOF', 'montant': 50000},
        ],
        'notifications_non_lues': 2,
      });

      expect(dashboard.demandesTotal, 4);
      expect(dashboard.missionsEnCours, 1);
      expect(dashboard.propositionsEnAttente, 1);
      expect(dashboard.depensesTotal.length, 2);
      expect(dashboard.depensesTotal[0].devise, 'XOF');
      expect(dashboard.depensesTotal[0].montant, 200000.0);
      expect(dashboard.depensesTotal[1].devise, 'GHS');
      expect(dashboard.depensesTotal[1].montant, 45000.0);
      expect(dashboard.depensesMois.single.montant, 50000.0);
      expect(dashboard.notificationsNonLues, 2);
    });

    test('defaults every field to 0/empty when the payload is empty', () {
      final dashboard = DashboardClientModel.fromJson({});

      expect(dashboard.demandesTotal, 0);
      expect(dashboard.depensesTotal, isEmpty);
      expect(dashboard.depensesMois, isEmpty);
      expect(dashboard.notificationsNonLues, 0);
    });
  });
}
