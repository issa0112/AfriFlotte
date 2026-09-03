import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/models/proposition.dart';

void main() {
  group('PropositionCamionInfo.fromJson', () {
    test('parses a camion with a chauffeur assigned', () {
      final info = PropositionCamionInfo.fromJson({
        'camion': 8,
        'camion_immatriculation': 'AB-1234',
        'chauffeur': 3,
        'chauffeur_nom': 'Moussa',
      });

      expect(info.camionId, 8);
      expect(info.chauffeurId, 3);
      expect(info.chauffeurNom, 'Moussa');
    });

    test('parses a camion with no chauffeur (nullable field)', () {
      final info = PropositionCamionInfo.fromJson({
        'camion': 8,
        'camion_immatriculation': 'AB-1234',
        'chauffeur': null,
        'chauffeur_nom': null,
      });

      expect(info.chauffeurId, isNull);
      expect(info.chauffeurNom, isNull);
    });
  });

  group('Proposition.fromJson', () {
    test('parses a full proposition with its camions', () {
      final proposition = Proposition.fromJson({
        'id': 5,
        'demande': 2,
        'depart': 'Bamako',
        'destination': 'Kayes',
        'type_camion': 'CITERNE',
        'transporteur_nom': 'Iso Transport',
        'prix': '350000.00',
        'message': 'Disponible immédiatement',
        'delai_depart': '2026-08-22T08:00:00Z',
        'statut': 'ACCEPTEE',
        'camions': [
          {
            'camion': 8,
            'camion_immatriculation': 'AB-1234',
            'chauffeur': null,
            'chauffeur_nom': null,
          },
        ],
        'created_at': '2026-08-11T00:00:00Z',
      });

      expect(proposition.prix, 350000.0);
      expect(proposition.camions.length, 1);
      expect(proposition.statutLibelle, 'Acceptée');
    });

    test('statutLibelle defaults to "En attente" for unknown/missing statut', () {
      final proposition = Proposition.fromJson({
        'id': 1,
        'demande': 1,
        'prix': '100000',
        'camions': [],
      });

      expect(proposition.statutLibelle, 'En attente');
      expect(proposition.camions, isEmpty);
    });
  });
}
