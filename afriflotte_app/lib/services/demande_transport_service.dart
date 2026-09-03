import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/demande_transport.dart';
import 'api_service.dart';
import 'authenticated_http.dart';

class DemandeTransportService {
  /// `/demandes/` est filtré côté Django : un compte ENTREPRISE ne reçoit
  /// que ses propres demandes, un TRANSPORTEUR celles encore ouvertes.
  static Future<List<DemandeTransport>> getDemandes(String token) async {
    try {
      final response = await AuthenticatedHttp
          .get(
            Uri.parse("${ApiService.baseUrl}/demandes/"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
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
            .map(DemandeTransport.fromJson)
            .toList();
      }

      if (response.statusCode == 401) {
        throw Exception("Session expirée. Reconnectez-vous.");
      }

      throw Exception("Erreur chargement demandes (${response.statusCode})");
    } on TimeoutException {
      throw Exception("Délai dépassé. Vérifiez la connexion réseau.");
    } on SocketException {
      throw Exception(
        "Serveur injoignable. Vérifiez votre connexion et que Django tourne.",
      );
    }
  }

  /// PATCH `/demandes/<id>/` — uniquement possible tant que la demande est
  /// encore OUVERTE côté serveur (cf. DemandeTransportSerializer.validate).
  /// Renvoie la réponse brute (pas d'exception sur erreur HTTP) : l'appelant
  /// gère le statut lui-même, comme pour la création dans le même écran.
  static Future<http.Response> modifierDemande({
    required String token,
    required int demandeId,
    required Map<String, dynamic> data,
  }) {
    return AuthenticatedHttp.patch(
      Uri.parse("${ApiService.baseUrl}/demandes/$demandeId/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );
  }
}
