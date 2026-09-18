import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Flux "mot de passe oublié" — non authentifié par nature (l'utilisateur ne
/// peut justement pas se connecter). Identifié par email (seul canal de
/// récupération disponible, pas de passerelle SMS) : c'est aussi à cette
/// adresse que part le code de réinitialisation (voir `core/views.py` /
/// `core/services.py:envoyer_email_reinitialisation` côté Django) — il n'est
/// jamais renvoyé dans la réponse API.
class MotDePasseOublieService {
  static String _messageErreur(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final detail = body['detail'];
        if (detail is String) return detail;
      }
    } catch (_) {}
    return "Une erreur est survenue (${response.statusCode})";
  }

  /// Retourne `{"message": "...", "expire_dans_minutes": 15}` — le code
  /// lui-même n'est jamais présent ici, il part par email.
  static Future<Map<String, dynamic>> demanderCode(String email) async {
    final response = await http
        .post(
          Uri.parse("${ApiService.baseUrl}/mot-de-passe-oublie/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_messageErreur(response));
  }

  static Future<void> confirmerReinitialisation({
    required String email,
    required String code,
    required String nouveauMotDePasse,
  }) async {
    final response = await http
        .post(
          Uri.parse("${ApiService.baseUrl}/mot-de-passe-oublie/confirmer/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": email,
            "code": code,
            "nouveau_mot_de_passe": nouveauMotDePasse,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_messageErreur(response));
    }
  }
}
