import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/models/demande_transport.dart';

void main() {
  group('DemandeTransport.fromJson', () {
    test('prefers depart/destination over ville_depart/ville_arrivee', () {
      final demande = DemandeTransport.fromJson({
        'id': 1,
        'depart': 'Bamako',
        'ville_depart': 'Autre',
        'destination': 'Ségou',
        'ville_arrivee': 'Autre2',
        'produit': 'Essence',
        'type_camion': 'CITERNE',
        'nombre_camions': 1,
        'statut': 'OUVERTE',
        'quantite': '5000',
        'unite': 'litres',
      });

      expect(demande.depart, 'Bamako');
      expect(demande.destination, 'Ségou');
      expect(demande.trajet, 'Bamako → Ségou');
    });

    test(
      'falls back to ville_depart/ville_arrivee/description when the friendly fields are absent',
      () {
        final demande = DemandeTransport.fromJson({
          'id': 2,
          'ville_depart': 'Kayes',
          'ville_arrivee': 'Nioro',
          'description': 'Ciment',
          'type_camion': 'BENNE',
          'nombre_camions': 3,
          'statut': 'OUVERTE',
          'quantite': '12',
          'unite': 'tonnes',
        });

        expect(demande.depart, 'Kayes');
        expect(demande.destination, 'Nioro');
        expect(demande.produit, 'Ciment');
        expect(demande.nombreCamions, 3);
      },
    );

    test('parses numeric fields sent as strings', () {
      final demande = DemandeTransport.fromJson({
        'id': 3,
        'depart': 'Bamako',
        'destination': 'Gao',
        'type_camion': 'CITERNE',
        'nombre_camions': 1,
        'statut': 'OUVERTE',
        'quantite': '5000.50',
        'unite': 'litres',
        'prix_propose': '300000',
      });

      expect(demande.quantite, 5000.5);
      expect(demande.prixPropose, 300000.0);
    });
  });
}
