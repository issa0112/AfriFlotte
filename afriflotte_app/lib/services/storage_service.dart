import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';


class StorageService {


  static const String tokenKey = "access_token";

  static const String refreshTokenKey = "refresh_token";

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
      return;
    }

    await _secureStorage.delete(key: tokenKey);
    await _secureStorage.delete(key: refreshTokenKey);

  }

}
