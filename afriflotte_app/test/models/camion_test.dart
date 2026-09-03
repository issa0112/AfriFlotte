import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/models/camion.dart';

void main() {
  group('Camion.fromJson', () {
    test('parses a full camion with images', () {
      final camion = Camion.fromJson({
        'id': 4,
        'type_camion': 'CITERNE',
        'immatriculation': 'AB-1234-MD',
        'marque': 'Volvo',
        'modele': 'FH16',
        'annee': 2020,
        'capacite': '40000.00',
        'unite_capacite': 'litres',
        'disponible': true,
        'ville': 'Bamako',
        'latitude': '12.639200',
        'longitude': '-8.002900',
        'images': [
          {'id': 1, 'image': 'http://x/a.png', 'principale': false},
          {'id': 2, 'image': 'http://x/b.png', 'principale': true},
        ],
      });

      expect(camion.id, 4);
      expect(camion.typeCamion, 'CITERNE');
      expect(camion.immatriculation, 'AB-1234-MD');
      expect(camion.capacite, 40000.0);
      expect(camion.latitude, closeTo(12.6392, 0.0001));
      expect(camion.images.length, 2);
      expect(camion.imagePrincipaleUrl, 'http://x/b.png');
    });

    test('falls back to defaults when optional fields are missing', () {
      final camion = Camion.fromJson({
        'id': 1,
        'immatriculation': 'AB-0001',
        'capacite': '20000',
      });

      expect(camion.typeCamion, '');
      expect(camion.marque, '');
      expect(camion.uniteCapacite, 'litres');
      expect(camion.disponible, true);
      expect(camion.ville, 'Bamako');
      expect(camion.latitude, isNull);
      expect(camion.images, isEmpty);
      expect(camion.imagePrincipaleUrl, isNull);
    });

    test('picks the first image when none is marked principale', () {
      final camion = Camion.fromJson({
        'id': 1,
        'immatriculation': 'AB-0001',
        'capacite': '20000',
        'images': [
          {'id': 5, 'image': 'http://x/first.png', 'principale': false},
          {'id': 6, 'image': 'http://x/second.png', 'principale': false},
        ],
      });

      expect(camion.imagePrincipaleUrl, 'http://x/first.png');
    });
  });
}
