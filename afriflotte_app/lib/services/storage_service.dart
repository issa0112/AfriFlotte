import 'package:shared_preferences/shared_preferences.dart';


class StorageService {


  static const String tokenKey = "access_token";

  static const String refreshTokenKey = "refresh_token";



  // Enregistrer le token

  static Future<void> saveToken(
      String token
  ) async {

    final prefs =
        await SharedPreferences.getInstance();


    await prefs.setString(
      tokenKey,
      token
    );

  }



  // Récupérer le token

  static Future<String?> getToken() async {

    final prefs =
        await SharedPreferences.getInstance();


    return prefs.getString(
      tokenKey
    );

  }



  // Enregistrer le refresh token (obtenu à la connexion, utilisé pour
  // demander un nouveau token d'accès sans redemander le mot de passe).

  static Future<void> saveRefreshToken(String refreshToken) async {

    final prefs =
        await SharedPreferences.getInstance();


    await prefs.setString(
      refreshTokenKey,
      refreshToken
    );

  }



  // Récupérer le refresh token

  static Future<String?> getRefreshToken() async {

    final prefs =
        await SharedPreferences.getInstance();


    return prefs.getString(
      refreshTokenKey
    );

  }



  // Supprimer le token et le refresh token (déconnexion)

  static Future<void> clear() async {

    final prefs =
        await SharedPreferences.getInstance();


    await prefs.remove(
      tokenKey
    );

    await prefs.remove(
      refreshTokenKey
    );

  }

}