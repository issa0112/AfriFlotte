/// Référentiel partagé pour le périmètre sous-régional CEDEAO.
///
/// Miroir Django : core/constants.py — toute modification ici doit être
/// reportée là-bas à la main, aucun outillage de génération commune n'existe.
class PaysCedeao {
  final String code;
  final String nom;
  final String devise;
  final String indicatif;

  const PaysCedeao({
    required this.code,
    required this.nom,
    required this.devise,
    required this.indicatif,
  });
}

const List<PaysCedeao> paysCedeaoListe = [
  PaysCedeao(code: 'BJ', nom: 'Bénin', devise: 'XOF', indicatif: '+229'),
  PaysCedeao(code: 'BF', nom: 'Burkina Faso', devise: 'XOF', indicatif: '+226'),
  PaysCedeao(code: 'CV', nom: 'Cap-Vert', devise: 'CVE', indicatif: '+238'),
  PaysCedeao(code: 'CI', nom: "Côte d'Ivoire", devise: 'XOF', indicatif: '+225'),
  PaysCedeao(code: 'GM', nom: 'Gambie', devise: 'GMD', indicatif: '+220'),
  PaysCedeao(code: 'GH', nom: 'Ghana', devise: 'GHS', indicatif: '+233'),
  PaysCedeao(code: 'GN', nom: 'Guinée', devise: 'GNF', indicatif: '+224'),
  PaysCedeao(code: 'GW', nom: 'Guinée-Bissau', devise: 'XOF', indicatif: '+245'),
  PaysCedeao(code: 'LR', nom: 'Liberia', devise: 'LRD', indicatif: '+231'),
  PaysCedeao(code: 'ML', nom: 'Mali', devise: 'XOF', indicatif: '+223'),
  PaysCedeao(code: 'NE', nom: 'Niger', devise: 'XOF', indicatif: '+227'),
  PaysCedeao(code: 'NG', nom: 'Nigeria', devise: 'NGN', indicatif: '+234'),
  PaysCedeao(code: 'SN', nom: 'Sénégal', devise: 'XOF', indicatif: '+221'),
  PaysCedeao(code: 'SL', nom: 'Sierra Leone', devise: 'SLE', indicatif: '+232'),
  PaysCedeao(code: 'TG', nom: 'Togo', devise: 'XOF', indicatif: '+228'),
];

const String _deviseParDefaut = 'XOF';

/// Devise d'un code pays CEDEAO. Contrairement au backend, retombe sur XOF
/// (la devise la plus répandue dans la zone) plutôt que null si le code est
/// absent/inconnu : un libellé de prix doit toujours afficher quelque chose.
String deviseParPays(String? code) {
  if (code == null) return _deviseParDefaut;
  for (final pays in paysCedeaoListe) {
    if (pays.code == code) return pays.devise;
  }
  return _deviseParDefaut;
}

String? nomParPays(String? code) {
  if (code == null) return null;
  for (final pays in paysCedeaoListe) {
    if (pays.code == code) return pays.nom;
  }
  return null;
}

/// Indicatif téléphonique international d'un code pays CEDEAO (ex. '+223'
/// pour 'ML'), ou `null` si le code est absent/inconnu — contrairement à
/// `deviseParPays`, pas de repli : composer un numéro avec un mauvais
/// indicatif serait pire que ne rien afficher.
String? indicatifParPays(String? code) {
  if (code == null) return null;
  for (final pays in paysCedeaoListe) {
    if (pays.code == code) return pays.indicatif;
  }
  return null;
}

/// Formate un montant avec sa devise, ex. `formatMontant(125000, 'XOF')` ->
/// `"125 000 XOF"`. `montant` peut être `null` (prix pas encore fixé).
///
/// `devise` est déjà un code devise (ex. venant du champ `devise` renvoyé par
/// l'API, ou de `deviseParPays(paysCode)` calculé par l'appelant) — cette
/// fonction ne fait PAS de résolution pays->devise elle-même, seulement un
/// repli d'affichage si `devise` est absent.
String formatMontant(num? montant, String? devise) {
  if (montant == null) return 'Non défini';
  final code = (devise == null || devise.isEmpty) ? _deviseParDefaut : devise;
  return '${montant.toStringAsFixed(0)} $code';
}
