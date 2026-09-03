/// Un total de revenus pour une devise donnée, tel que renvoyé par
/// `RevenuDeviseSerializer` côté Django dans les champs
/// revenus/revenus_mois/revenus_annee (`DashboardTransporteurModel`) et
/// revenus_total (`AdminDashboardModel`).
///
/// Jamais un total unique : un transporteur (ou la plateforme) peut avoir
/// des missions terminées dans plusieurs pays CEDEAO, donc plusieurs
/// devises différentes — d'où cette ventilation en liste.
class RevenuDevise {
  final String devise;
  final double montant;

  const RevenuDevise({required this.devise, required this.montant});

  factory RevenuDevise.fromJson(Map<String, dynamic> json) {
    return RevenuDevise(
      devise: json['devise']?.toString() ?? '',
      montant: _asDouble(json['montant']) ?? 0,
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Parse une liste JSON de `{devise, montant}` en `List<RevenuDevise>` —
/// champ absent/mal formé -> liste vide plutôt que planter l'écran.
///
/// La liste est déjà triée par montant décroissant côté backend
/// (`revenus_par_devise` dans core/services.py) : `first` est donc toujours
/// la devise dominante.
List<RevenuDevise> revenusParDeviseDepuisJson(dynamic json) {
  if (json is! List) return [];
  return json
      .whereType<Map<String, dynamic>>()
      .map(RevenuDevise.fromJson)
      .toList();
}
