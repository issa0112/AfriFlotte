import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/models/chauffeur.dart';

void main() {
  group('Chauffeur.fromJson', () {
    test('parses a chauffeur with a camion actuel assigned', () {
      final chauffeur = Chauffeur.fromJson({
        'id': 3,
        'nom': 'Moussa',
        'telephone': '76543210',
        'numero_permis': 'PERMIS-1',
        'date_expiration_permis': '2028-01-01',
        'code_acces': '1234',
        'disponible': true,
        'actif': true,
        'camion_actuel': {
          'id': 9,
          'immatriculation': 'AB-1234',
          'type_camion': 'CITERNE',
          'marque': 'Volvo',
          'modele': 'FH16',
        },
        'camion_actuel_id': 9,
      });

      expect(chauffeur.nom, 'Moussa');
      expect(chauffeur.aUnCamion, isTrue);
      expect(chauffeur.camionActuel!.immatriculation, 'AB-1234');
    });

    test('parses a chauffeur with no camion assigned', () {
      final chauffeur = Chauffeur.fromJson({
        'id': 4,
        'nom': 'Ali',
        'telephone': '76543211',
        'numero_permis': 'PERMIS-2',
        'code_acces': '',
        'camion_actuel': null,
      });

      expect(chauffeur.aUnCamion, isFalse);
      expect(chauffeur.camionActuel, isNull);
    });

    test('defaults disponible/actif to true when absent', () {
      final chauffeur = Chauffeur.fromJson({
        'id': 5,
        'nom': 'Karim',
        'telephone': '76543212',
        'numero_permis': 'PERMIS-3',
        'code_acces': '',
      });

      expect(chauffeur.disponible, isTrue);
      expect(chauffeur.actif, isTrue);
    });
  });

  group('Affectation.fromJson', () {
    test('parses an active affectation', () {
      final affectation = Affectation.fromJson({
        'id': 1,
        'chauffeur': 3,
        'chauffeur_nom': 'Moussa',
        'camion': 9,
        'camion_immatriculation': 'AB-1234',
        'date_debut': '2026-08-01T10:00:00Z',
        'date_fin': null,
        'commentaire': '',
        'active': true,
      });

      expect(affectation.active, isTrue);
      expect(affectation.dateFin, isNull);
      expect(affectation.chauffeurNom, 'Moussa');
    });
  });
}
