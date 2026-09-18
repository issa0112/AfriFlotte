import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/contrat.dart';
import 'api_service.dart';
import 'authenticated_http.dart';

/// Contrats légaux (`core/contrats.py` côté Django) : contenu public — pas
/// besoin de token pour les lire ou en récupérer le PDF, seule leur
/// acceptation (transporteur) exige une session authentifiée.
class ContratService {
  static Future<Contrat> getContratPaiement() => _get('/contrats/paiement/');

  static Future<Contrat> getContratTransporteur() =>
      _get('/contrats/transporteur/');

  static Future<Contrat> _get(String chemin) async {
    final response = await http
        .get(Uri.parse('${ApiService.baseUrl}$chemin'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger ce contrat.');
    }

    return Contrat.depuisJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static String get urlPdfContratPaiement =>
      '${ApiService.baseUrl}/contrats/paiement/pdf/';

  static String get urlPdfContratTransporteur =>
      '${ApiService.baseUrl}/contrats/transporteur/pdf/';

  /// Enregistre l'acceptation du contrat transporteur pour l'utilisateur
  /// authentifié par `token` — rejeté (403) côté serveur si ce n'est pas un
  /// compte TRANSPORTEUR.
  static Future<void> accepterContratTransporteur(String token) async {
    final response = await AuthenticatedHttp.post(
      Uri.parse('${ApiService.baseUrl}/contrats/transporteur/accepter/'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception("Impossible d'enregistrer l'acceptation du contrat.");
    }
  }
}
