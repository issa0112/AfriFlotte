import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/position_gps.dart';
import 'api_service.dart';
import 'authenticated_http.dart';

class PositionService {
  static Map<String, dynamic> _decodeMap(String body) {
    if (body.isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static String _messageErreur(String body) {
    final decoded = _decodeMap(body);

    if (decoded.containsKey('detail') && decoded['detail'] != null) {
      final value = decoded['detail'];
      return value is List && value.isNotEmpty
          ? value.first.toString()
          : value.toString();
    }

    if (decoded.containsKey('message') && decoded['message'] != null) {
      return decoded['message'].toString();
    }

    if (decoded.isNotEmpty) {
      final premier = decoded.entries.first.value;
      return premier is List && premier.isNotEmpty
          ? premier.first.toString()
          : premier.toString();
    }

    return 'Erreur inattendue';
  }

  /// Ping GPS pour `missionCamionId` — alimente `resoudre_position_camion`
  /// côté serveur et l'historique consultable via [getHistorique].
  static Future<void> envoyerPosition({
    required String token,
    required int missionCamionId,
    required double latitude,
    required double longitude,
    double? vitesse,
    double? precision,
  }) async {
    try {
      final response = await AuthenticatedHttp
          .post(
            Uri.parse('${ApiService.baseUrl}/tracking/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'mission_camion': missionCamionId,
              'latitude': latitude,
              'longitude': longitude,
              if (vitesse != null) 'vitesse': vitesse,
              if (precision != null) 'precision': precision,
              'source': 'GPS',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) return;

      throw Exception(_messageErreur(response.body));
    } on TimeoutException {
      throw Exception('Délai dépassé. Vérifiez la connexion réseau.');
    } on SocketException {
      throw Exception(
        'Serveur injoignable. Vérifiez votre connexion et que Django tourne.',
      );
    }
  }

  /// Les 50 derniers pings du camion, du plus récent au plus ancien.
  static Future<List<PositionGps>> getHistorique({
    required String token,
    required int missionCamionId,
  }) async {
    try {
      final response = await AuthenticatedHttp
          .get(
            Uri.parse('${ApiService.baseUrl}/tracking/$missionCamionId/historique/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final items = decoded is List
            ? decoded
            : (decoded is Map && decoded['results'] is List
                  ? decoded['results'] as List
                  : const []);

        return items
            .whereType<Map<String, dynamic>>()
            .map(PositionGps.fromJson)
            .toList();
      }

      throw Exception(_messageErreur(response.body));
    } on TimeoutException {
      throw Exception('Délai dépassé. Vérifiez la connexion réseau.');
    } on SocketException {
      throw Exception(
        'Serveur injoignable. Vérifiez votre connexion et que Django tourne.',
      );
    }
  }
}
