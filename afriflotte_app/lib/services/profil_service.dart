import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import 'authenticated_http.dart';

/// Appels liés à l'écran "Mon profil" (transporteur ET client, qui partagent
/// le même modèle `User` côté Django) : mise à jour des informations
/// personnelles, photo de profil et changement de mot de passe. Séparé de
/// [ApiService] pour les mêmes raisons que [CamionService] etc. — un fichier
/// par domaine plutôt qu'un service monolithique.
class ProfilService {
  static String _messageErreur(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        for (final cle in ['detail', 'email', 'pays', 'photo_profil', 'non_field_errors']) {
          final valeur = body[cle];
          if (valeur == null) continue;
          if (valeur is List && valeur.isNotEmpty) return valeur.first.toString();
          return valeur.toString();
        }
      }
    } catch (_) {}
    return "Une erreur est survenue (${response.statusCode})";
  }

  /// PATCH /profil/ — met à jour nom_entreprise/email/adresse/pays et
  /// renvoie l'objet utilisateur complet à jour, prêt à remplacer celui
  /// gardé en mémoire côté app (pas de re-login nécessaire).
  static Future<Map<String, dynamic>> mettreAJourProfil({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await AuthenticatedHttp.patch(
      Uri.parse("${ApiService.baseUrl}/profil/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_messageErreur(response));
  }

  /// PATCH multipart /profil/ — remplace la photo de profil et renvoie
  /// l'utilisateur à jour (même contrat que [mettreAJourProfil]). `XFile` (et
  /// non `dart:io.File`) pour rester compatible Flutter Web, comme pour les
  /// photos de camion (voir `CamionService.uploadImageCamion`).
  static Future<Map<String, dynamic>> mettreAJourPhotoProfil({
    required String token,
    required XFile photo,
  }) async {
    final octets = await photo.readAsBytes();

    final response = await AuthenticatedHttp.multipartPatch(
      Uri.parse("${ApiService.baseUrl}/profil/"),
      headers: {"Authorization": "Bearer $token"},
      construireFichiers: () async => [
        http.MultipartFile.fromBytes(
          "photo_profil",
          octets,
          filename: photo.name,
        ),
      ],
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_messageErreur(response));
  }

  /// POST /profil/mot-de-passe/ — le token JWT en cours reste valide après
  /// coup (simplejwt n'invalide pas les tokens existants au changement de
  /// mot de passe), donc aucune reconnexion forcée n'est nécessaire.
  static Future<void> changerMotDePasse({
    required String token,
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    final response = await AuthenticatedHttp.post(
      Uri.parse("${ApiService.baseUrl}/profil/mot-de-passe/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "ancien_mot_de_passe": ancienMotDePasse,
        "nouveau_mot_de_passe": nouveauMotDePasse,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_messageErreur(response));
    }
  }
}
