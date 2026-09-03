import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/litige.dart';
import '../models/paiement.dart';
import 'api_service.dart';
import 'authenticated_http.dart';

class PaiementService {
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
    if (decoded['message'] != null) return decoded['message'].toString();
    return 'Erreur inattendue';
  }

  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  /// `/missions/<id>/paiement/initier/` : crée le paiement de la mission.
  /// En mode CARTE, la transaction est aussi initiée côté passerelle. Selon
  /// le prestataire actif (`core/gateway_paiement.py`), la réponse contient
  /// ou non `checkout_url` :
  /// - présent (PayDunya, page hébergée) : à ouvrir dans une WebView
  ///   intégrée (`paiement_webview_screen.dart`), pas un navigateur externe.
  /// - absent (simulateur, formulaire natif) : le client saisit sa carte
  ///   dans `paiement_carte_screen.dart`, confirmé via
  ///   `confirmerPaiementCarte`.
  static Future<(Paiement, String?)> initierPaiement({
    required String token,
    required int missionId,
    required String mode,
  }) async {
    try {
      final response = await AuthenticatedHttp.post(
        Uri.parse(
          '${ApiService.baseUrl}/missions/$missionId/paiement/initier/',
        ),
        headers: _headers(token),
        body: jsonEncode({'mode': mode}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (Paiement.fromJson(data), data['checkout_url']?.toString());
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

  /// `/paiements/<id>/confirmer-carte/` : appelé juste après que le client a
  /// saisi et validé sa carte dans le formulaire intégré. `marque`/`dernier4`/
  /// `expiration` sont les seules informations transmises — jamais le numéro
  /// complet ni le CVV (cf. `core/gateway_paiement.py`).
  static Future<Paiement> confirmerPaiementCarte({
    required String token,
    required int paiementId,
    required String marque,
    required String dernier4,
    required String expiration,
  }) async {
    try {
      final response = await AuthenticatedHttp.post(
        Uri.parse(
          '${ApiService.baseUrl}/paiements/$paiementId/confirmer-carte/',
        ),
        headers: _headers(token),
        body: jsonEncode({
          'carte_marque': marque,
          'carte_dernier4': dernier4,
          'carte_expiration': expiration,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 202) {
        return Paiement.fromJson(jsonDecode(response.body));
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

  static Future<Paiement?> getPaiementMission({
    required String token,
    required int missionId,
  }) async {
    final response = await AuthenticatedHttp.get(
      Uri.parse('${ApiService.baseUrl}/missions/$missionId/paiement/'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return Paiement.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 404) return null;

    throw Exception(_messageErreur(response.body));
  }

  static Future<List<Paiement>> mesPaiements(String token) async {
    final response = await AuthenticatedHttp.get(
      Uri.parse('${ApiService.baseUrl}/mes-paiements/'),
      headers: _headers(token),
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
          .map(Paiement.fromJson)
          .toList();
    }

    throw Exception(_messageErreur(response.body));
  }

  /// File d'attente admin — `statut` optionnel (`ENCAISSE`, `LIBERE`...),
  /// sinon le backend renvoie par défaut ce qui est à traiter.
  static Future<List<Paiement>> adminPaiements(
    String token, {
    String? statut,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/admin/paiements/',
    ).replace(queryParameters: statut != null ? {'statut': statut} : null);
    final response = await AuthenticatedHttp.get(
      uri,
      headers: _headers(token),
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
          .map(Paiement.fromJson)
          .toList();
    }

    throw Exception(_messageErreur(response.body));
  }

  static Future<List<Litige>> adminLitiges(
    String token, {
    String? statut,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/admin/litiges/',
    ).replace(queryParameters: statut != null ? {'statut': statut} : null);
    final response = await AuthenticatedHttp.get(
      uri,
      headers: _headers(token),
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
          .map(Litige.fromJson)
          .toList();
    }

    throw Exception(_messageErreur(response.body));
  }

  /// Paiements MANUEL en attente d'encaissement, visibles par tout agent
  /// AfriFlotte (pas de notion de propriété — cf. `AgentPaiementsView`).
  static Future<List<Paiement>> paiementsAEncaisser(String token) async {
    final response = await AuthenticatedHttp.get(
      Uri.parse('${ApiService.baseUrl}/agent/paiements-a-encaisser/'),
      headers: _headers(token),
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
          .map(Paiement.fromJson)
          .toList();
    }

    throw Exception(_messageErreur(response.body));
  }

  /// Agent AfriFlotte : déclare avoir encaissé l'argent en espèces, avec une
  /// preuve (photo du reçu/signature). `preuve` accepte `null` : l'API ne
  /// l'exige pas au niveau HTTP, mais un agent devrait toujours en fournir
  /// une en pratique — validé côté écran, pas ici.
  static Future<Paiement> encaisserManuel({
    required String token,
    required int paiementId,
    required String reference,
    XFile? preuve,
    String commentaire = '',
  }) async {
    final response = await AuthenticatedHttp.multipartPost(
      Uri.parse(
        '${ApiService.baseUrl}/paiements/$paiementId/encaisser-manuel/',
      ),
      headers: {'Authorization': 'Bearer $token'},
      fields: {'reference': reference, 'commentaire': commentaire},
      construireFichiers: preuve == null
          ? null
          : () async => [
              http.MultipartFile.fromBytes(
                'preuve',
                await preuve.readAsBytes(),
                filename: preuve.name,
              ),
            ],
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return Paiement.fromJson(jsonDecode(response.body));
    }
    throw Exception(_messageErreur(response.body));
  }

  static Future<Paiement> validerManuel({
    required String token,
    required int paiementId,
  }) async {
    final response = await AuthenticatedHttp.post(
      Uri.parse('${ApiService.baseUrl}/paiements/$paiementId/valider/'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return Paiement.fromJson(jsonDecode(response.body));
    }
    throw Exception(_messageErreur(response.body));
  }

  static Future<Paiement> verser({
    required String token,
    required int paiementId,
    required String reference,
    XFile? preuve,
    String commentaire = '',
  }) async {
    final response = await AuthenticatedHttp.multipartPost(
      Uri.parse('${ApiService.baseUrl}/paiements/$paiementId/verser/'),
      headers: {'Authorization': 'Bearer $token'},
      fields: {'reference': reference, 'commentaire': commentaire},
      construireFichiers: preuve == null
          ? null
          : () async => [
              http.MultipartFile.fromBytes(
                'preuve',
                await preuve.readAsBytes(),
                filename: preuve.name,
              ),
            ],
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return Paiement.fromJson(jsonDecode(response.body));
    }
    throw Exception(_messageErreur(response.body));
  }

  static Future<Paiement> rembourser({
    required String token,
    required int paiementId,
    required String motif,
  }) async {
    final response = await AuthenticatedHttp.post(
      Uri.parse('${ApiService.baseUrl}/paiements/$paiementId/rembourser/'),
      headers: _headers(token),
      body: jsonEncode({'motif': motif}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return Paiement.fromJson(jsonDecode(response.body));
    }
    throw Exception(_messageErreur(response.body));
  }

  static Future<Litige> ouvrirLitige({
    required String token,
    required int paiementId,
    required String motif,
  }) async {
    final response = await AuthenticatedHttp.post(
      Uri.parse('${ApiService.baseUrl}/paiements/$paiementId/litiges/'),
      headers: _headers(token),
      body: jsonEncode({'motif': motif}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      return Litige.fromJson(jsonDecode(response.body));
    }
    throw Exception(_messageErreur(response.body));
  }

  static Future<Litige> resoudreLitige({
    required String token,
    required int litigeId,
    required String resolution,
    String commentaire = '',
  }) async {
    final response = await AuthenticatedHttp.post(
      Uri.parse('${ApiService.baseUrl}/litiges/$litigeId/resoudre/'),
      headers: _headers(token),
      body: jsonEncode({'resolution': resolution, 'commentaire': commentaire}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return Litige.fromJson(jsonDecode(response.body));
    }
    throw Exception(_messageErreur(response.body));
  }
}
