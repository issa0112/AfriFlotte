/// Validation et détection de marque pour le formulaire de carte bancaire
/// intégré (`paiement_carte_screen.dart`) — fonctions pures, sans dépendance
/// Flutter, pour rester testables indépendamment du widget.
///
/// Rappel de sécurité (cf. `core/gateway_paiement.py`) : le numéro complet et
/// le CVV ne doivent jamais quitter l'appareil. Ce module ne fait que valider
/// localement puis exposer `marqueCarte`/`dernier4` — les seules informations
/// envoyées au backend.
library;

final RegExp _nonChiffre = RegExp(r'\D');

enum MarqueCarte { visa, mastercard, amex, autre }

String libelleMarque(MarqueCarte marque) {
  switch (marque) {
    case MarqueCarte.visa:
      return 'Visa';
    case MarqueCarte.mastercard:
      return 'Mastercard';
    case MarqueCarte.amex:
      return 'American Express';
    case MarqueCarte.autre:
      return 'Carte';
  }
}

/// Code court envoyé au backend (métadonnée d'affichage uniquement).
String codeMarque(MarqueCarte marque) {
  switch (marque) {
    case MarqueCarte.visa:
      return 'VISA';
    case MarqueCarte.mastercard:
      return 'MASTERCARD';
    case MarqueCarte.amex:
      return 'AMEX';
    case MarqueCarte.autre:
      return 'AUTRE';
  }
}

/// Détecte la marque par préfixe (règles standard des réseaux de cartes).
MarqueCarte detecterMarque(String numeroBrut) {
  final numero = numeroBrut.replaceAll(_nonChiffre, '');
  if (numero.isEmpty) return MarqueCarte.autre;

  if (numero.startsWith('4')) return MarqueCarte.visa;

  if (numero.startsWith(RegExp(r'^(34|37)'))) return MarqueCarte.amex;

  final deuxChiffres = numero.length >= 2 ? int.tryParse(numero.substring(0, 2)) : null;
  final quatreChiffres = numero.length >= 4 ? int.tryParse(numero.substring(0, 4)) : null;
  if (deuxChiffres != null && deuxChiffres >= 51 && deuxChiffres <= 55) {
    return MarqueCarte.mastercard;
  }
  if (quatreChiffres != null && quatreChiffres >= 2221 && quatreChiffres <= 2720) {
    return MarqueCarte.mastercard;
  }

  return MarqueCarte.autre;
}

/// Longueur de CVV attendue pour la marque (Amex : 4 chiffres, les autres : 3).
int longueurCvvAttendue(MarqueCarte marque) => marque == MarqueCarte.amex ? 4 : 3;

/// Algorithme de Luhn — vrai si `numeroBrut` (une fois les espaces retirés)
/// est une suite de chiffres valide selon la formule de contrôle standard des
/// cartes bancaires.
bool _luhnValide(String numero) {
  var somme = 0;
  var doubler = false;
  for (var i = numero.length - 1; i >= 0; i--) {
    var chiffre = int.parse(numero[i]);
    if (doubler) {
      chiffre *= 2;
      if (chiffre > 9) chiffre -= 9;
    }
    somme += chiffre;
    doubler = !doubler;
  }
  return somme % 10 == 0;
}

/// Message d'erreur (ou `null` si valide) pour le champ numéro de carte.
String? validerNumeroCarte(String numeroBrut) {
  final numero = numeroBrut.replaceAll(_nonChiffre, '');
  if (numero.isEmpty) return 'Le numéro de carte est obligatoire';
  if (numero.length < 13 || numero.length > 19) return 'Numéro de carte invalide';
  if (!_luhnValide(numero)) return 'Numéro de carte invalide';
  return null;
}

/// Message d'erreur (ou `null`) pour le champ expiration, saisi "MM/AA".
String? validerExpiration(String moisAnnee, {DateTime? maintenant}) {
  final valeur = moisAnnee.trim();
  final correspondance = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(valeur);
  if (correspondance == null) return 'Format attendu : MM/AA';

  final mois = int.parse(correspondance.group(1)!);
  final annee = int.parse(correspondance.group(2)!);
  if (mois < 1 || mois > 12) return 'Mois invalide';

  final ref = maintenant ?? DateTime.now();
  final anneeCourteRef = ref.year % 100;
  final estExpiree = annee < anneeCourteRef || (annee == anneeCourteRef && mois < ref.month);
  if (estExpiree) return 'Carte expirée';

  return null;
}

/// Message d'erreur (ou `null`) pour le champ CVV, selon la marque détectée.
String? validerCvv(String cvvBrut, MarqueCarte marque) {
  final cvv = cvvBrut.replaceAll(_nonChiffre, '');
  final longueur = longueurCvvAttendue(marque);
  if (cvv.length != longueur) return 'CVV invalide ($longueur chiffres)';
  return null;
}

/// Message d'erreur (ou `null`) pour le nom du titulaire.
String? validerNomTitulaire(String nom) {
  return nom.trim().isEmpty ? 'Le nom du titulaire est obligatoire' : null;
}

/// 4 derniers chiffres du numéro, pour l'affichage/stockage ("Visa •••• 4242").
String dernier4(String numeroBrut) {
  final numero = numeroBrut.replaceAll(_nonChiffre, '');
  return numero.length >= 4 ? numero.substring(numero.length - 4) : numero;
}

/// Formate le numéro de carte en groupes de 4 chiffres pour l'affichage
/// pendant la saisie (ex. "4242 4242 4242 4242").
String formaterNumeroCarte(String numeroBrut) {
  final numero = numeroBrut.replaceAll(_nonChiffre, '');
  final groupes = <String>[];
  for (var i = 0; i < numero.length; i += 4) {
    groupes.add(numero.substring(i, i + 4 > numero.length ? numero.length : i + 4));
  }
  return groupes.join(' ');
}
