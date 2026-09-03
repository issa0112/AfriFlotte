import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/models/camion_recherche.dart';

void main() {
  group('PositionResolue.fromJson', () {
    test('parses a resolved position', () {
      final position = PositionResolue.fromJson({
        'latitude': 12.6392,
        'longitude': -8.0029,
        'source': 'CHAUFFEUR',
        'updated_at': '2026-08-11T02:17:40Z',
        'fraicheur': 'TRES_FIABLE',
      });

      expect(position.source, 'CHAUFFEUR');
      expect(position.fraicheur, 'TRES_FIABLE');
      expect(position.updatedAt, isNotNull);
    });
  });

  group('CamionRecherche.fromJson', () {
    test('parses a camion with a resolved position and a distance', () {
      final camion = CamionRecherche.fromJson({
        'id': 5,
        'type_camion': 'CITERNE',
        'immatriculation': 'QA-POS-A',
        'marque': 'Volvo',
        'modele': 'FH16',
        'capacite': '40000.00',
        'unite_capacite': 'litres',
        'disponible': true,
        'ville': 'Bamako',
        'position': {
          'latitude': 12.6392,
          'longitude': -8.0029,
          'source': 'CAMION',
          'updated_at': '2026-08-11T02:17:40Z',
          'fraicheur': 'TRES_FIABLE',
        },
        'distance_km': 0.3,
      });

      expect(camion.position, isNotNull);
      expect(camion.position!.source, 'CAMION');
      expect(camion.distanceKm, 0.3);
    });

    test('parses a camion with no known position', () {
      final camion = CamionRecherche.fromJson({
        'id': 1,
        'type_camion': 'CITERNE',
        'immatriculation': 'AX324GH',
        'marque': 'HOWO',
        'modele': '430',
        'capacite': '43500.00',
        'unite_capacite': 'litres',
        'disponible': true,
        'ville': 'Bamako',
        'position': null,
        'distance_km': null,
      });

      expect(camion.position, isNull);
      expect(camion.distanceKm, isNull);
    });
  });
}
