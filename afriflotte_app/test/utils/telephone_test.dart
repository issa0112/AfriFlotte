import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/utils/telephone.dart';

void main() {
  group('normaliserTelephone', () {
    test('Mali : numéro local valide', () {
      expect(normaliserTelephone('ML', '70707070'), '+22370707070');
      expect(normaliserTelephone('ML', '60606060'), '+22360606060');
    });

    test('Sénégal : numéro valide', () {
      expect(normaliserTelephone('SN', '771234567'), '+221771234567');
    });

    test("Côte d'Ivoire : numéro à 10 chiffres (réforme 2021)", () {
      expect(normaliserTelephone('CI', '0712345678'), '+2250712345678');
    });

    test('Bénin : numéro avec le "01" permanent', () {
      expect(normaliserTelephone('BJ', '0142345678'), '+2290142345678');
    });

    test('Ghana : zéro domestique accepté et retiré au stockage', () {
      expect(normaliserTelephone('GH', '0244123456'), '+233244123456');
      expect(normaliserTelephone('GH', '244123456'), '+233244123456');
    });

    test('tolère un numéro déjà composé (indicatif + local)', () {
      expect(normaliserTelephone('ML', '+22370707070'), '+22370707070');
    });

    test('Mali : préfixe invalide lève une exception', () {
      expect(
        () => normaliserTelephone('ML', '12345678'),
        throwsA(isA<TelephoneInvalideException>()),
      );
    });

    test('Mali : longueur invalide lève une exception', () {
      expect(
        () => normaliserTelephone('ML', '707070'),
        throwsA(isA<TelephoneInvalideException>()),
      );
    });

    test('pays inconnu lève une exception', () {
      expect(
        () => normaliserTelephone('XX', '70707070'),
        throwsA(isA<TelephoneInvalideException>()),
      );
    });
  });

  group('validerNumeroLocal', () {
    test('renvoie null pour un numéro valide', () {
      expect(validerNumeroLocal('ML', '70707070'), isNull);
    });

    test('renvoie un message pour un numéro invalide', () {
      expect(validerNumeroLocal('ML', '12345678'), isNotNull);
    });

    test('renvoie null pour un champ vide (le champ requis est géré ailleurs)', () {
      expect(validerNumeroLocal('ML', ''), isNull);
      expect(validerNumeroLocal('ML', null), isNull);
    });
  });

  group('formaterLocal', () {
    test('retire l\'indicatif pour un pays sans zéro domestique', () {
      expect(formaterLocal('+22370707070', 'ML'), '70707070');
    });

    test('réinsère le zéro domestique pour le Ghana', () {
      expect(formaterLocal('+233244123456', 'GH'), '0244123456');
    });

    test('numéro non migré (sans indicatif) renvoyé tel quel', () {
      expect(formaterLocal('70707070', 'ML'), '70707070');
    });

    test('renvoie null si le numéro est null', () {
      expect(formaterLocal(null, 'ML'), isNull);
    });
  });
}
