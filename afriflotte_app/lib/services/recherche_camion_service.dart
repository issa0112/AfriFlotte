import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/camion_recherche.dart';
import 'api_service.dart';
import 'authenticated_http.dart';

class RechercheCamionService {
  /// `/recherche-camions/` : `latitude`/`longitude` sont le point de
  /// référence de la recherche (position actuelle du client, ou ville de
  /// départ) — sans eux, le tri se fait uniquement sur la fraîcheur GPS.
  static Future<List<CamionRecherche>> rechercher({
    required String token,
    String? typeCamion,
    String? formatCamion,
    double? capaciteMin,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final params = <String, String>{'disponible': 'true'};
      if (typeCamion != null) params['type_camion'] = typeCamion;
      if (formatCamion != null && formatCamion.isNotEmpty) {
        params['format_camion'] = formatCamion;
      }
      if (capaciteMin != null) params['capacite_min'] = '$capaciteMin';
      if (latitude != null) params['latitude'] = '$latitude';
      if (longitude != null) params['longitude'] = '$longitude';

      final uri = Uri.parse(
        '${ApiService.baseUrl}/recherche-camions/',
      ).replace(queryParameters: params);

      final response = await AuthenticatedHttp.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final items = decoded is List
            ? decoded
            : (decoded is Map && decoded['results'] is List
                  ? decoded['results'] as List
                  : const []);

        return items
            .whereType<Map<String, dynamic>>()
            .map(CamionRecherche.fromJson)
            .toList();
      }

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Reconnectez-vous.');
      }

      throw Exception('Erreur recherche camions (${response.statusCode})');
    } on TimeoutException {
      throw Exception('Délai dépassé. Vérifiez la connexion réseau.');
    } on SocketException {
      throw Exception(
        'Serveur injoignable. Vérifiez votre connexion et que Django tourne.',
      );
    }
  }

  /// `/transporteur/flotte-positions/` : TOUS les camions du transporteur
  /// connecté (disponibles ou en mission), chacun avec le chauffeur affecté
  /// et sa position résolue — l'écran "où sont mes camions/chauffeurs".
  /// Contrairement à [rechercher] (marché, camions disponibles uniquement),
  /// aucun filtre/point de référence n'est nécessaire ici.
  static Future<List<CamionRecherche>> mesPositionsFlotte(String token) async {
    try {
      final response = await AuthenticatedHttp.get(
        Uri.parse('${ApiService.baseUrl}/transporteur/flotte-positions/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final items = decoded is List
            ? decoded
            : (decoded is Map && decoded['results'] is List
                  ? decoded['results'] as List
                  : const []);

        return items
            .whereType<Map<String, dynamic>>()
            .map(CamionRecherche.fromJson)
            .toList();
      }

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Reconnectez-vous.');
      }

      throw Exception(
        'Erreur chargement de la flotte (${response.statusCode})',
      );
    } on TimeoutException {
      throw Exception('Délai dépassé. Vérifiez la connexion réseau.');
    } on SocketException {
      throw Exception(
        'Serveur injoignable. Vérifiez votre connexion et que Django tourne.',
      );
    }
  }
}
