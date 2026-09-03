import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/mission.dart';
import 'api_service.dart';
import 'authenticated_http.dart';

class MissionService {
  static String _messageErreur(String body) {
    if (body.isEmpty) return 'Erreur inattendue';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return 'Erreur inattendue';
  }

  static Future<void> _postAction(String token, String endpoint) async {
    try {
      final response = await AuthenticatedHttp
          .post(
            Uri.parse('${ApiService.baseUrl}$endpoint'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return;

      if (response.statusCode == 403) {
        throw Exception("Vous n'êtes pas autorisé à faire cette action.");
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

  /// Démarre une mission planifiée : PLANIFIEE -> EN_COURS.
  static Future<void> accepterMission(String token, int missionId) {
    return _postAction(token, '/missions/$missionId/accepter/');
  }

  /// Annule une mission (planifiée ou en cours) -> ANNULEE.
  static Future<void> refuserMission(String token, int missionId) {
    return _postAction(token, '/missions/$missionId/refuser/');
  }

  /// Clôture une mission en cours -> TERMINEE, libère camion(s)/chauffeur(s).
  static Future<void> terminerMission(String token, int missionId) {
    return _postAction(token, '/missions/$missionId/terminer/');
  }

  /// `/missions/` est filtré côté Django : un compte ENTREPRISE ne reçoit
  /// que ses propres missions.
  static Future<List<Mission>> getMissions(String token) async {
    try {
      final response = await AuthenticatedHttp
          .get(
            Uri.parse('${ApiService.baseUrl}/missions/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // DRF renvoie une liste, ou un objet paginé selon la configuration.
        final items = decoded is List
            ? decoded
            : (decoded is Map && decoded['results'] is List
                  ? decoded['results'] as List
                  : const []);

        return items
            .whereType<Map<String, dynamic>>()
            .map(Mission.fromJson)
            .toList();
      }

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Reconnectez-vous.');
      }

      throw Exception('Erreur chargement missions (${response.statusCode})');
    } on TimeoutException {
      throw Exception('Délai dépassé. Vérifiez la connexion réseau.');
    } on SocketException {
      throw Exception(
        'Serveur injoignable. Vérifiez votre connexion et que Django tourne.',
      );
    }
  }
}
