import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Wrapper autour de `package:http` qui intercepte les réponses 401 : si un
/// appel authentifié échoue parce que le token a expiré, tente un
/// rafraîchissement (`ApiService.refreshAccessToken`) puis rejoue la requête
/// UNE fois avec le nouveau token avant d'abandonner. Avant ce wrapper,
/// [TokenRefreshScheduler] ne pouvait éviter les 401 que si l'écran
/// concerné se reconstruisait entre-temps (changement d'onglet, pull-to-
/// refresh...) — un écran resté immobile plus de 5 minutes gardait un token
/// périmé jusqu'au prochain rebuild. Ce wrapper couvre ce cas résiduel en
/// rattrapant l'échec au niveau de l'appel réseau lui-même.
///
/// Signatures volontairement proches de `http.get`/`http.post`/etc. : chaque
/// appelant n'a qu'à remplacer `http.xxx(...)` par `AuthenticatedHttp.xxx(...)`
/// sans changer le reste de sa logique (parsing de réponse, gestion
/// d'erreurs...). Le header `Authorization` doit déjà être présent dans
/// `headers` — ce wrapper le REMPLACE par le token rafraîchi avant de
/// rejouer la requête, il ne l'ajoute pas de zéro. Les appels sans en-tête
/// `Authorization` (login, register, refresh lui-même, endpoints chauffeur
/// qui n'utilisent pas de JWT) ne passent jamais par le chemin de retry.
class AuthenticatedHttp {
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _avecRetry(headers, (h) => http.get(url, headers: h));
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _avecRetry(headers, (h) => http.post(url, headers: h, body: body));
  }

  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _avecRetry(headers, (h) => http.patch(url, headers: h, body: body));
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _avecRetry(headers, (h) => http.delete(url, headers: h, body: body));
  }

  /// Variante multipart (upload de fichier) — `construireFichiers` est un
  /// *fabricant*, pas une liste déjà construite : `http.MultipartFile` est
  /// adossé à un flux de fichier qui ne peut être lu qu'une fois, donc en
  /// cas de retry il faut reconstruire les parties fichier depuis le chemin
  /// d'origine plutôt que de réutiliser l'instance de la première tentative.
  static Future<http.Response> multipartPost(
    Uri url, {
    required Map<String, String> headers,
    Map<String, String>? fields,
    Future<List<http.MultipartFile>> Function()? construireFichiers,
  }) {
    return _multipartRequest(
      'POST',
      url,
      headers: headers,
      fields: fields,
      construireFichiers: construireFichiers,
    );
  }

  /// Même logique que [multipartPost], en `PATCH` — utile pour mettre à jour
  /// un champ fichier unique sur une ressource existante (photo de profil,
  /// photo de chauffeur) sans dupliquer toute la ressource comme le ferait
  /// un `POST` sur une collection.
  static Future<http.Response> multipartPatch(
    Uri url, {
    required Map<String, String> headers,
    Map<String, String>? fields,
    Future<List<http.MultipartFile>> Function()? construireFichiers,
  }) {
    return _multipartRequest(
      'PATCH',
      url,
      headers: headers,
      fields: fields,
      construireFichiers: construireFichiers,
    );
  }

  static Future<http.Response> _multipartRequest(
    String method,
    Uri url, {
    required Map<String, String> headers,
    Map<String, String>? fields,
    Future<List<http.MultipartFile>> Function()? construireFichiers,
  }) {
    return _avecRetry(headers, (h) async {
      final request = http.MultipartRequest(method, url);
      request.headers.addAll(h ?? const {});
      if (fields != null) request.fields.addAll(fields);
      if (construireFichiers != null) {
        request.files.addAll(await construireFichiers());
      }

      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    });
  }

  static Future<http.Response> _avecRetry(
    Map<String, String>? headers,
    Future<http.Response> Function(Map<String, String>? headers) executer,
  ) async {
    final reponse = await executer(headers);

    if (reponse.statusCode != 401 ||
        headers == null ||
        !headers.containsKey('Authorization')) {
      return reponse;
    }

    final nouveauToken = await ApiService.refreshAccessToken();
    if (nouveauToken == null) return reponse;

    final headersRafraichis = Map<String, String>.from(headers)
      ..['Authorization'] = 'Bearer $nouveauToken';

    return executer(headersRafraichis);
  }
}
