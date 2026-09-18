import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';


class StorageService {


  static const String tokenKey = "access_token";

  static const String refreshTokenKey = "refresh_token";

  // Le compte chauffeur n'a pas de JWT (cf. `ChauffeurLoginView` côté
  // Django) : le code d'accès (= mot de passe) rejoué à chaque appel en
  // tient lieu. Pour rester connecté d'une ouverture d'app à l'autre comme
  // les autres comptes, on garde telephone+code_acces ici et on rejoue un
  // login silencieux au démarrage (voir `splash_screen.dart`).
  static const String chauffeurTelephoneKey = "chauffeur_telephone";

  static const String chauffeurCodeAccesKey = "chauffeur_code_acces";

  // Sur mobile/desktop, le token est chiffré et stocké hors du périmètre de
  // la sauvegarde automatique Android/iCloud (contrairement à
  // SharedPreferences) — ça évite qu'un token d'un autre compte, restauré
  // depuis un backup, ne connecte silencieusement le mauvais utilisateur au
  // démarrage. Sur le web, il n'y a pas de backup système équivalent à
  // craindre, donc on garde SharedPreferences (plus simple, pas de
  // dépendance à WebCrypto).
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();



  // Enregistrer le token

  static Future<void> saveToken(
      String token
  ) async {

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
      return;
    }

    await _secureStorage.write(key: tokenKey, value: token);

  }



  // Récupérer le token

  static Future<String?> getToken() async {

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(tokenKey);
    }

    return _secureStorage.read(key: tokenKey);

  }



  // Enregistrer le refresh token (obtenu à la connexion, utilisé pour
  // demander un nouveau token d'accès sans redemander le mot de passe).

  static Future<void> saveRefreshToken(String refreshToken) async {

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(refreshTokenKey, refreshToken);
      return;
    }

    await _secureStorage.write(key: refreshTokenKey, value: refreshToken);

  }



  // Récupérer le refresh token

  static Future<String?> getRefreshToken() async {

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(refreshTokenKey);
    }

    return _secureStorage.read(key: refreshTokenKey);

  }



  // Supprimer le token et le refresh token (déconnexion)

  static Future<void> clear() async {

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(refreshTokenKey);
      await prefs.remove(chauffeurTelephoneKey);
      await prefs.remove(chauffeurCodeAccesKey);
      return;
    }

    await _secureStorage.delete(key: tokenKey);
    await _secureStorage.delete(key: refreshTokenKey);
    await _secureStorage.delete(key: chauffeurTelephoneKey);
    await _secureStorage.delete(key: chauffeurCodeAccesKey);

  }



  // Enregistrer la session chauffeur (telephone saisi + code d'accès), pour
  // la reprendre silencieusement au prochain démarrage de l'app.

  static Future<void> saveChauffeurSession({
    required String telephone,
    required String codeAcces,
  }) async {

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(chauffeurTelephoneKey, telephone);
      await prefs.setString(chauffeurCodeAccesKey, codeAcces);
      return;
    }

    await _secureStorage.write(key: chauffeurTelephoneKey, value: telephone);
    await _secureStorage.write(key: chauffeurCodeAccesKey, value: codeAcces);

  }



  // Récupérer la session chauffeur stockée : `null` si aucune (soit qu'on ne
  // s'est jamais connecté en chauffeur, soit qu'on s'en est déconnecté).

  static Future<({String telephone, String codeAcces})?> getChauffeurSession() async {

    final String? telephone;
    final String? codeAcces;

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      telephone = prefs.getString(chauffeurTelephoneKey);
      codeAcces = prefs.getString(chauffeurCodeAccesKey);
    } else {
      telephone = await _secureStorage.read(key: chauffeurTelephoneKey);
      codeAcces = await _secureStorage.read(key: chauffeurCodeAccesKey);
    }

    if (telephone == null || telephone.isEmpty || codeAcces == null || codeAcces.isEmpty) {
      return null;
    }

    return (telephone: telephone, codeAcces: codeAcces);

  }

}
