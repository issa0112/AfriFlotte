import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/models/mission.dart';

void main() {
  group('Mission.fromJson', () {
    test('parses a full mission', () {
      final mission = Mission.fromJson({
        'id': 7,
        'demande': 2,
        'depart': 'Bamako',
        'destination': 'Kayes',
        'produit': 'Essence',
        'type_camion': 'CITERNE',
        'statut': 'EN_COURS',
        'statut_libelle': 'En cours',
        'transporteur_nom': 'Iso Transport',
        'nombre_camions': 2,
        'prix_final': '300000.00',
        'date_chargement': '2026-08-20',
        'date_creation': '2026-08-10T00:00:00Z',
        'date_depart': '2026-08-20T08:00:00Z',
        'date_arrivee': null,
      });

      expect(mission.trajet, 'Bamako → Kayes');
      expect(mission.estEnCours, isTrue);
      expect(mission.estTerminee, isFalse);
      expect(mission.prixFinal, 300000.0);
      expect(mission.dateArrivee, isNull);
    });

    test('falls back to friendly defaults when fields are missing', () {
      final mission = Mission.fromJson({'id': 1});

      expect(mission.depart, 'Départ inconnu');
      expect(mission.destination, 'Destination inconnue');
      expect(mission.produit, 'Marchandise non précisée');
      expect(mission.transporteurNom, 'Transporteur non assigné');
      expect(mission.statut, 'PLANIFIEE');
      expect(mission.nombreCamions, 0);
      expect(mission.prixFinal, isNull);
    });
  });
}
