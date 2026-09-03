import 'dart:convert';

import '../models/camion.dart';
import '../models/chauffeur.dart';
import '../models/demande_transport.dart';
import '../models/mission.dart';
import '../models/utilisateur_admin.dart';
import 'api_service.dart';
import 'authenticated_http.dart';

/// Vues admin "plateforme" (`/admin/utilisateurs|chauffeurs|camions|missions|
/// demandes/`) — non scopées à `request.user`, réservées aux comptes ADMIN.
/// Alimentent les écrans ouverts depuis les cartes de `dashboard_admin.dart`.
class AdminService {
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  static String _messageErreur(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return 'Erreur inattendue';
  }

  static List<dynamic> _liste(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['results'] is List) {
      return decoded['results'] as List;
    }
    return const [];
  }

  static Future<List<UtilisateurAdmin>> getUtilisateurs({
    required String token,
    required String typeCompte,
  }) async {
    final response = await AuthenticatedHttp.get(
      Uri.parse(
        '${ApiService.baseUrl}/admin/utilisateurs/?type_compte=$typeCompte',
      ),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _liste(response.body)
          .whereType<Map<String, dynamic>>()
          .map(UtilisateurAdmin.fromJson)
          .toList();
    }
    throw Exception(_messageErreur(response.body));
  }

  static Future<List<Chauffeur>> getChauffeurs(String token) async {
    final response = await AuthenticatedHttp.get(
      Uri.parse('${ApiService.baseUrl}/admin/chauffeurs/'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _liste(
        response.body,
      ).whereType<Map<String, dynamic>>().map(Chauffeur.fromJson).toList();
    }
    throw Exception(_messageErreur(response.body));
  }

  static Future<List<Camion>> getCamions(String token) async {
    final response = await AuthenticatedHttp.get(
      Uri.parse('${ApiService.baseUrl}/admin/camions/'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _liste(
        response.body,
      ).whereType<Map<String, dynamic>>().map(Camion.fromJson).toList();
    }
    throw Exception(_messageErreur(response.body));
  }

  static Future<List<Mission>> getMissions(String token) async {
    final response = await AuthenticatedHttp.get(
      Uri.parse('${ApiService.baseUrl}/admin/missions/'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _liste(
        response.body,
      ).whereType<Map<String, dynamic>>().map(Mission.fromJson).toList();
    }
    throw Exception(_messageErreur(response.body));
  }

  static Future<List<DemandeTransport>> getDemandes(String token) async {
    final response = await AuthenticatedHttp.get(
      Uri.parse('${ApiService.baseUrl}/admin/demandes/'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _liste(response.body)
          .whereType<Map<String, dynamic>>()
          .map(DemandeTransport.fromJson)
          .toList();
    }
    throw Exception(_messageErreur(response.body));
  }
}
