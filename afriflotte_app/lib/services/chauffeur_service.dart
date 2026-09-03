import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/chauffeur.dart';
import 'api_service.dart';
import 'authenticated_http.dart';

class ChauffeurService {
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

    if (decoded.isNotEmpty) {
      final premier = decoded.entries.first.value;
      return premier is List && premier.isNotEmpty
          ? premier.first.toString()
          : premier.toString();
    }

    return 'Erreur inattendue';
  }

  /// `/chauffeurs/` est filtré côté Django sur le transporteur connecté.
  static Future<List<Chauffeur>> getChauffeurs(String token) async {
    try {
      final response = await AuthenticatedHttp
          .get(
            Uri.parse('${ApiService.baseUrl}/chauffeurs/'),
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
            .map(Chauffeur.fromJson)
            .toList();
      }

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Reconnectez-vous.');
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

  static Future<Chauffeur> createChauffeur({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await AuthenticatedHttp
          .post(
            Uri.parse('${ApiService.baseUrl}/chauffeurs/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return Chauffeur.fromJson(jsonDecode(response.body));
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

  /// PATCH multipart `/chauffeurs/{id}/` — remplace la photo d'un chauffeur
  /// déjà enregistré. Séparé de [createChauffeur] (qui reste en JSON) pour
  /// les mêmes raisons que `CamionService.uploadImageCamion` est séparé de
  /// `createCamion` : la photo est optionnelle et peut être ajoutée/changée
  /// après coup, à la création ou plus tard depuis la liste des chauffeurs.
  static Future<Chauffeur> uploaderPhotoChauffeur({
    required String token,
    required int chauffeurId,
    required XFile photo,
  }) async {
    final octets = await photo.readAsBytes();

    final response = await AuthenticatedHttp.multipartPatch(
      Uri.parse('${ApiService.baseUrl}/chauffeurs/$chauffeurId/'),
      headers: {'Authorization': 'Bearer $token'},
      construireFichiers: () async => [
        http.MultipartFile.fromBytes('photo', octets, filename: photo.name),
      ],
    );

    if (response.statusCode == 200) {
      return Chauffeur.fromJson(jsonDecode(response.body));
    }

    throw Exception(_messageErreur(response.body));
  }

  /// PATCH multipart `/chauffeur/{id}/photo/` — le chauffeur change sa
  /// propre photo depuis son tableau de bord. Contrairement à
  /// [uploaderPhotoChauffeur] (JWT transporteur, `/chauffeurs/{id}/`), cette
  /// route est ouverte par `chauffeur_id` sans token, comme le reste des
  /// endpoints chauffeur (voir `ChauffeurPhotoView` côté Django) — donc pas
  /// d'en-tête `Authorization` ici.
  static Future<String?> modifierMaPhoto({
    required int chauffeurId,
    required XFile photo,
  }) async {
    final octets = await photo.readAsBytes();

    final response = await AuthenticatedHttp.multipartPatch(
      Uri.parse('${ApiService.baseUrl}/chauffeur/$chauffeurId/photo/'),
      headers: const {},
      construireFichiers: () async => [
        http.MultipartFile.fromBytes('photo', octets, filename: photo.name),
      ],
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['photo']?.toString();
    }

    throw Exception(_messageErreur(response.body));
  }

  /// Historique des affectations, filtrable par `chauffeurId`, `camionId`
  /// et/ou `active`, comme le permet `/api/affectations/` côté Django.
  static Future<List<Affectation>> getAffectations(
    String token, {
    int? chauffeurId,
    int? camionId,
    bool? active,
  }) async {
    try {
      final params = <String, String>{};
      if (chauffeurId != null) params['chauffeur'] = '$chauffeurId';
      if (camionId != null) params['camion'] = '$camionId';
      if (active != null) params['active'] = active ? 'true' : 'false';

      final uri = Uri.parse(
        '${ApiService.baseUrl}/affectations/',
      ).replace(queryParameters: params.isEmpty ? null : params);

      final response = await AuthenticatedHttp
          .get(
            uri,
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
            .map(Affectation.fromJson)
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

  /// Assigne `camionId` à `chauffeurId`. Django clôture automatiquement,
  /// côté serveur, toute affectation encore ouverte sur ce camion ou ce
  /// chauffeur — inutile de le faire depuis Flutter.
  static Future<Affectation> assignerCamion({
    required String token,
    required int chauffeurId,
    required int camionId,
    String commentaire = '',
  }) async {
    try {
      final response = await AuthenticatedHttp
          .post(
            Uri.parse('${ApiService.baseUrl}/affectations/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'chauffeur': chauffeurId,
              'camion': camionId,
              'commentaire': commentaire,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return Affectation.fromJson(jsonDecode(response.body));
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

  /// Libère un camion : clôture l'affectation active sans effacer l'historique.
  static Future<void> terminerAffectation({
    required String token,
    required int affectationId,
  }) async {
    try {
      final response = await AuthenticatedHttp
          .post(
            Uri.parse(
              '${ApiService.baseUrl}/affectations/$affectationId/terminer/',
            ),
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
