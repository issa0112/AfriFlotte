import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/app_notification.dart';
import 'api_service.dart';
import 'authenticated_http.dart';

class NotificationService {
  /// `/notifications/` est filtré côté Django sur l'utilisateur connecté.
  static Future<List<AppNotification>> getNotifications(String token) async {
    try {
      final response = await AuthenticatedHttp
          .get(
            Uri.parse('${ApiService.baseUrl}/notifications/'),
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
            .map(AppNotification.fromJson)
            .toList();
      }

      throw Exception('Erreur chargement notifications (${response.statusCode})');
    } on TimeoutException {
      throw Exception('Délai dépassé. Vérifiez la connexion réseau.');
    } on SocketException {
      throw Exception(
        'Serveur injoignable. Vérifiez votre connexion et que Django tourne.',
      );
    }
  }

  static Future<void> marquerLue(String token, int notificationId) async {
    final response = await AuthenticatedHttp.post(
      Uri.parse('${ApiService.baseUrl}/notifications/$notificationId/lire/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour notification');
    }
  }

  static Future<void> marquerToutesLues(String token) async {
    final response = await AuthenticatedHttp.post(
      Uri.parse('${ApiService.baseUrl}/notifications/lire-toutes/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour des notifications');
    }
  }
}
