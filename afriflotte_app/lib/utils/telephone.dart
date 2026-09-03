/// Validation et normalisation des numéros de téléphone selon le plan de
/// numérotation de chaque pays CEDEAO.
///
/// Miroir Django : core/telephone.py — toute modification ici (nouveau pays,
/// correction de longueur/préfixe...) doit être reportée là-bas à la main,
/// même absence d'outillage commun que constants.py/pays_cedeao.dart.
///
/// Un numéro est toujours stocké en E.164 (indicatif + numéro national, sans
/// zéro initial, sans espace).
library;

import '../constants/pays_cedeao.dart';

class ReglePaysTelephone {
  final int longueur;
  final List<String> prefixes;

  const ReglePaysTelephone({required this.longueur, required this.prefixes});
}

/// Pour chaque pays : longueur du numéro national significatif (après
/// l'indicatif, sans zéro initial) et préfixes valides. Source : plans de
/// numérotation par pays (Wikipedia/ITU), recherchés le 2026-09-01 — voir
/// core/telephone.py pour le détail des sources et des limites connues
/// (Nigeria/Gambie/Liberia/Sierra Leone : préfixes larges par chiffre de
/// tête plutôt qu'une liste exhaustive, marché trop mouvant).
const Map<String, ReglePaysTelephone> reglesNumerotation = {
  'BJ': ReglePaysTelephone(longueur: 10, prefixes: ['01']),
  'BF': ReglePaysTelephone(longueur: 8, prefixes: ['6', '7']),
  'CV': ReglePaysTelephone(longueur: 7, prefixes: ['9']),
  'CI': ReglePaysTelephone(longueur: 10, prefixes: ['01', '05', '07']),
  'GM': ReglePaysTelephone(longueur: 7, prefixes: ['2', '3', '4', '5', '6', '9']),
  'GH': ReglePaysTelephone(
    longueur: 9,
    prefixes: [
      '20', '23', '24', '25', '26', '27', '28',
      '50', '53', '54', '55', '56', '57', '59',
    ],
  ),
  'GN': ReglePaysTelephone(longueur: 9, prefixes: ['6']),
  'GW': ReglePaysTelephone(longueur: 9, prefixes: ['9']),
  'LR': ReglePaysTelephone(longueur: 9, prefixes: ['5', '7', '8']),
  'ML': ReglePaysTelephone(longueur: 8, prefixes: ['6', '7']),
  'NE': ReglePaysTelephone(longueur: 8, prefixes: ['8', '9']),
  'NG': ReglePaysTelephone(longueur: 10, prefixes: ['7', '8', '9']),
  'SN': ReglePaysTelephone(longueur: 9, prefixes: ['7']),
  'SL': ReglePaysTelephone(longueur: 8, prefixes: ['2', '3', '4', '6', '7', '8']),
  'TG': ReglePaysTelephone(
    longueur: 8,
    prefixes: [
      '70', '71', '72', '73', '78', '79',
      '90', '91', '92', '93', '96', '97', '98', '99',
    ],
  ),
};

/// Pays où l'usage domestique courant compose le numéro avec un zéro initial
/// (ex. Ghana "0244123456") — sert uniquement à décider si `formaterLocal`
/// doit réinsérer ce zéro pour l'affichage.
const Set<String> paysAvecZeroLocal = {'GH', 'NG', 'SL'};

final RegExp _caracteresAIgnorer = RegExp(r'[\s\-().]');
final RegExp _nonChiffre = RegExp(r'\D');

class TelephoneInvalideException implements Exception {
  final String message;
  const TelephoneInvalideException(this.message);

  @override
  String toString() => message;
}

bool _correspond(String numeroNational, ReglePaysTelephone regle) {
  if (numeroNational.length != regle.longueur) return false;
  return regle.prefixes.any(numeroNational.startsWith);
}

/// Valide `telephoneBrut` (numéro local seul, ou déjà préfixé de l'indicatif)
/// pour le plan de numérotation de `codePays`, et renvoie la forme E.164
/// normalisée (`indicatif + numéro national`, sans zéro initial ni espace).
///
/// Lève [TelephoneInvalideException] si le numéro ne correspond à aucune
/// forme valide (ni tel quel, ni sans son premier zéro) pour ce pays.
String normaliserTelephone(String codePays, String telephoneBrut) {
  final indicatif = indicatifParPays(codePays);
  final regle = reglesNumerotation[codePays];
  if (indicatif == null || regle == null) {
    throw TelephoneInvalideException('Pays inconnu pour la validation du téléphone : $codePays');
  }

  var brut = telephoneBrut.trim().replaceAll(_caracteresAIgnorer, '');

  if (brut.startsWith(indicatif)) {
    brut = brut.substring(indicatif.length);
  } else if (brut.startsWith(indicatif.replaceFirst('+', ''))) {
    brut = brut.substring(indicatif.length - 1);
  }

  final numero = brut.replaceAll(_nonChiffre, '');

  final candidats = [numero];
  if (numero.startsWith('0') && numero.length > 1) {
    candidats.add(numero.substring(1));
  }

  for (final candidat in candidats) {
    if (_correspond(candidat, regle)) {
      return '$indicatif$candidat';
    }
  }

  final nom = nomParPays(codePays) ?? codePays;
  final prefixesLisibles = regle.prefixes.join('/');
  throw TelephoneInvalideException(
    'Numéro invalide pour $nom : ${regle.longueur} chiffres attendus après '
    "l'indicatif $indicatif (préfixe valide : $prefixesLisibles).",
  );
}

/// Message d'erreur (ou `null` si valide) prêt pour un `validator:` de
/// `TextFormField`/`Form`.
String? validerNumeroLocal(String codePays, String? numeroBrut) {
  if (numeroBrut == null || numeroBrut.trim().isEmpty) {
    return null;
  }
  try {
    normaliserTelephone(codePays, numeroBrut);
    return null;
  } on TelephoneInvalideException catch (e) {
    return e.message;
  }
}

/// Numéro en format d'affichage local : indicatif retiré, zéro domestique
/// ré-ajouté pour les pays qui l'utilisent en usage courant
/// (`paysAvecZeroLocal`). Renvoie `telephoneE164` tel quel si le pays est
/// inconnu ou si le numéro ne commence pas par son indicatif (donnée pas
/// encore migrée) — un numéro doit toujours afficher quelque chose.
String? formaterLocal(String? telephoneE164, String? codePays) {
  if (telephoneE164 == null || telephoneE164.isEmpty) return telephoneE164;

  final indicatif = codePays == null ? null : indicatifParPays(codePays);
  if (indicatif == null || !telephoneE164.startsWith(indicatif)) {
    return telephoneE164;
  }

  var local = telephoneE164.substring(indicatif.length);
  if (paysAvecZeroLocal.contains(codePays)) {
    local = '0$local';
  }
  return local;
}
