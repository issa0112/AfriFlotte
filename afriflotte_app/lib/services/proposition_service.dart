import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/proposition.dart';
import 'api_service.dart';
import 'authenticated_http.dart';

class PropositionService {
  static Map<String, dynamic> _decodeMap(String body) {
    if (body.isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  /// DRF renvoie `{"champ": ["message"]}` sur erreur de validation (ex :
  /// un camion qui n'appartient pas au transporteur) — on prend le premier
  /// message lisible plutôt que d'afficher le JSON brut.
  static String _messageErreur(String body) {
    final decoded = _decodeMap(body);

    if (decoded.containsKey('detail') && decoded['detail'] != null) {
      final value = decoded['detail'];
      return value is List && value.isNotEmpty
          ? value.first.toString()
          : value.toString();
    }

    if (decoded.isNotEmpty) {
      final premier = decoded.entries.first.value;
      if (premier is List && premier.isNotEmpty) {
        final valeur = premier.first;
        return valeur is Map && valeur.isNotEmpty
            ? valeur.values.first.toString()
            : valeur.toString();
      }
      return premier.toString();
    }

    return 'Erreur inattendue';
  }

  /// `/propositions/` est filtré côté Django sur le transporteur connecté.
  static Future<List<Proposition>> getPropositions(String token) async {
    try {
      final response = await AuthenticatedHttp
          .get(
            Uri.parse('${ApiService.baseUrl}/propositions/'),
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
            .map(Proposition.fromJson)
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

  static Future<Proposition> creerProposition({
    required String token,
    required int demandeId,
    required double prix,
    required List<PropositionCamionEntree> camions,
    String? message,
    DateTime? delaiDepart,
  }) async {
    try {
      final response = await AuthenticatedHttp
          .post(
            Uri.parse('${ApiService.baseUrl}/propositions/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'demande': demandeId,
              'prix': prix,
              if (message != null && message.trim().isNotEmpty)
                'message': message.trim(),
              if (delaiDepart != null)
                'delai_depart': delaiDepart.toIso8601String(),
              'camions': [
                for (var i = 0; i < camions.length; i++)
                  camions[i].toJson(i + 1),
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return Proposition.fromJson(jsonDecode(response.body));
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

  /// Accepte une proposition côté entreprise : crée la mission, refuse les
  /// autres propositions de la même demande (géré côté Django).
  static Future<void> accepterProposition(String token, int id) async {
    await _poster(token, '${ApiService.baseUrl}/propositions/$id/accepter/');
  }

  /// Refuse une proposition côté entreprise, sans toucher aux autres
  /// propositions de la même demande.
  static Future<void> refuserProposition(String token, int id) async {
    await _poster(token, '${ApiService.baseUrl}/propositions/$id/refuser/');
  }

  static Future<void> _poster(String token, String url) async {
    try {
      final response = await AuthenticatedHttp
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return;

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
