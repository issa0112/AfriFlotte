import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/utils/carte_bancaire.dart';

void main() {
  group('detecterMarque', () {
    test('Visa (préfixe 4)', () {
      expect(detecterMarque('4242424242424242'), MarqueCarte.visa);
    });

    test('Mastercard (préfixe 51-55)', () {
      expect(detecterMarque('5555555555554444'), MarqueCarte.mastercard);
    });

    test('Mastercard (nouvelle plage 2221-2720)', () {
      expect(detecterMarque('2223003122003222'), MarqueCarte.mastercard);
    });

    test('American Express (préfixe 34/37)', () {
      expect(detecterMarque('378282246310005'), MarqueCarte.amex);
    });

    test('marque inconnue (ex. Discover) retombe sur "autre"', () {
      expect(detecterMarque('6011111111111117'), MarqueCarte.autre);
    });

    test('ignore les espaces de saisie', () {
      expect(detecterMarque('4242 4242 4242 4242'), MarqueCarte.visa);
    });
  });

  group('validerNumeroCarte', () {
    test('accepte un numéro Visa valide (Luhn)', () {
      expect(validerNumeroCarte('4242424242424242'), isNull);
    });

    test('accepte un numéro Amex valide (15 chiffres)', () {
      expect(validerNumeroCarte('378282246310005'), isNull);
    });

    test('rejette un numéro qui échoue à Luhn', () {
      expect(validerNumeroCarte('4242424242424241'), isNotNull);
    });

    test('rejette un numéro trop court', () {
      expect(validerNumeroCarte('4242'), isNotNull);
    });

    test('rejette un champ vide', () {
      expect(validerNumeroCarte(''), isNotNull);
    });
  });

  group('validerExpiration', () {
    final reference = DateTime(2026, 9, 1);

    test('accepte une date future', () {
      expect(validerExpiration('12/29', maintenant: reference), isNull);
    });

    test('accepte le mois courant', () {
      expect(validerExpiration('09/26', maintenant: reference), isNull);
    });

    test('rejette une date passée', () {
      expect(validerExpiration('01/20', maintenant: reference), isNotNull);
    });

    test('rejette un mois invalide', () {
      expect(validerExpiration('13/29', maintenant: reference), isNotNull);
    });

    test('rejette un format incorrect', () {
      expect(validerExpiration('1229', maintenant: reference), isNotNull);
    });
  });

  group('validerCvv', () {
    test('accepte 3 chiffres pour Visa/Mastercard', () {
      expect(validerCvv('123', MarqueCarte.visa), isNull);
    });

    test('rejette 3 chiffres pour Amex', () {
      expect(validerCvv('123', MarqueCarte.amex), isNotNull);
    });

    test('accepte 4 chiffres pour Amex', () {
      expect(validerCvv('1234', MarqueCarte.amex), isNull);
    });

    test('rejette un CVV trop court', () {
      expect(validerCvv('12', MarqueCarte.visa), isNotNull);
    });
  });

  group('dernier4', () {
    test('extrait les 4 derniers chiffres', () {
      expect(dernier4('4242424242424242'), '4242');
    });
  });

  group('formaterNumeroCarte', () {
    test('groupe par blocs de 4 chiffres', () {
      expect(formaterNumeroCarte('4242424242424242'), '4242 4242 4242 4242');
    });

    test('gère une saisie partielle', () {
      expect(formaterNumeroCarte('424242'), '4242 42');
    });
  });
}
