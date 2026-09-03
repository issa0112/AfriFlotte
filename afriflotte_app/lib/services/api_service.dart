import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/dashboard_transporteur_model.dart';
import 'authenticated_http.dart';
import 'storage_service.dart';

class ApiService {
  static String _extractErrorMessage(Map<String, dynamic> body) {
    if (body.containsKey("detail") && body["detail"] != null) {
      final value = body["detail"];
      if (value is List && value.isNotEmpty) return value.first.toString();
      return value.toString();
    }

    if (body.containsKey("telephone") && body["telephone"] != null) {
      final value = body["telephone"];
      if (value is List && value.isNotEmpty) return value.first.toString();
      return value.toString();
    }

    if (body.containsKey("password") && body["password"] != null) {
      final value = body["password"];
      if (value is List && value.isNotEmpty) return value.first.toString();
      return value.toString();
    }

    if (body.containsKey("non_field_errors") &&
        body["non_field_errors"] != null) {
      final value = body["non_field_errors"];
      if (value is List && value.isNotEmpty) return value.first.toString();
      return value.toString();
    }

    if (body.containsKey("message") && body["message"] != null) {
      return body["message"].toString();
    }

    return "Erreur de connexion";
  }

  /// URL de l'API injectée à la compilation pour un build de production,
  /// ex. `flutter build apk --dart-define=API_BASE_URL=https://afriflotte.up.railway.app/api`
  /// (idem pour `flutter build web`). Vide par défaut : `flutter run`/les
  /// builds de dev sans cette option gardent exactement le comportement
  /// ci-dessous, inchangé.
  static const String _urlApiProduction = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// IMPORTANT (uniquement si `API_BASE_URL` n'est pas fourni au build) :
  /// - Web: 127.0.0.1 fonctionne si le navigateur est sur la même machine que Django.
  /// - Android émulateur: 10.0.2.2 pointe vers localhost du PC.
  /// - Android réel: remplacer par l'IP LAN de votre PC (ex: 192.168.1.20).
  /// - iOS simulateur: localhost/127.0.0.1 fonctionne souvent.
  static String get baseUrl {
    if (_urlApiProduction.isNotEmpty) {
      return _urlApiProduction;
    }

    if (kIsWeb) {
      return "http://127.0.0.1:8000/api";
    }

    if (Platform.isAndroid) {
      const bool useEmulator = true;
      if (useEmulator) {
        return "http://10.0.2.2:8000/api";
      }
      return "http://192.168.1.20:8000/api";
    }

    if (Platform.isIOS) {
      return "http://127.0.0.1:8000/api";
    }

    return "http://127.0.0.1:8000/api";
  }

  // Connexion utilisateur
  static Future<Map<String, dynamic>> login(
    String telephone,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/login/"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"telephone": telephone, "password": password}),
          )
          // 20s, pas 10s : la vérification du mot de passe (PBKDF2, ~1.2M
          // itérations par défaut côté Django) peut à elle seule prendre
          // plusieurs secondes sur du matériel modeste — un timeout trop
          // court déclenchait un faux échec de connexion suivi d'un essai
          // de connexion chauffeur (401) déroutant.
          .timeout(const Duration(seconds: 20));

      debugPrint("STATUS : ${response.statusCode}");
      debugPrint("REPONSE : ${response.body}");

      Map<String, dynamic> body = {};
      if (response.body.isNotEmpty) {
        try {
          body = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          body = {};
        }
      }

      if (response.statusCode == 200) {
        return {"success": true, "data": body, "message": "Connexion réussie"};
      }

      if (response.statusCode == 401 || response.statusCode == 400) {
        return {
          "success": false,
          "message": _extractErrorMessage(body),
          "statusCode": response.statusCode,
        };
      }

      return {
        "success": false,
        "message": _extractErrorMessage(body),
        "statusCode": response.statusCode,
      };
    } on TimeoutException {
      return {
        "success": false,
        "message": "Délai dépassé. Vérifiez la connexion réseau.",
      };
    } on SocketException {
      return {
        "success": false,
        "message":
            "Serveur injoignable. Vérifiez l'URL API et que Django tourne sur le bon hôte/port.",
      };
    } catch (e) {
      return {"success": false, "message": "Erreur inattendue: $e"};
    }
  }

  /// Demande un nouveau token d'accès via le refresh token stocké
  /// (`/api/token/refresh/`, django-rest-framework-simplejwt). Le token
  /// d'accès expire au bout de 5 minutes côté Django (aucun `SIMPLE_JWT`
  /// personnalisé dans `settings.py`, donc valeur par défaut de la lib) —
  /// c'est ce que [TokenRefreshScheduler] appelle périodiquement pour éviter
  /// à l'utilisateur de se reconnecter en pleine session.
  ///
  /// Retourne le nouveau token d'accès et le sauvegarde via [StorageService],
  /// ou `null` si le refresh token est absent/expiré (le refresh token dure
  /// ~1 jour par défaut) — dans ce cas l'appelant ne fait rien de spécial,
  /// le prochain appel API échouera avec un 401 normal, comme avant ce
  /// correctif, et l'utilisateur devra se reconnecter avec son mot de passe.
  static Future<String?> refreshAccessToken() async {
    final refreshToken = await StorageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/token/refresh/"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"refresh": refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final nouveauToken = body["access"]?.toString();
      if (nouveauToken == null || nouveauToken.isEmpty) return null;

      await StorageService.saveToken(nouveauToken);

      // `ROTATE_REFRESH_TOKENS=True` côté Django (voir settings.py) : chaque
      // rafraîchissement renvoie aussi un nouveau refresh token, avec une
      // échéance repoussée de 180 jours — c'est ce qui permet à une session
      // active de ne jamais expirer tant que l'app est réouverte. Sans ce
      // `saveRefreshToken`, le refresh token d'origine restait utilisé
      // indéfiniment sans que son échéance ne recule jamais.
      final nouveauRefreshToken = body["refresh"]?.toString();
      if (nouveauRefreshToken != null && nouveauRefreshToken.isNotEmpty) {
        await StorageService.saveRefreshToken(nouveauRefreshToken);
      }

      return nouveauToken;
    } catch (_) {
      return null;
    }
  }

  /// Création de compte transporteur/entreprise. `username` est déduit du
  /// téléphone : l'app est pensée "connexion par téléphone" de bout en bout,
  /// inutile de demander un identifiant séparé à l'inscription.
  static Future<Map<String, dynamic>> register({
    required String telephone,
    required String password,
    required String typeCompte,
    String? nomEntreprise,
    String? email,
    String pays = 'ML',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/register/"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": telephone,
              "telephone": telephone,
              "password": password,
              "type_compte": typeCompte,
              "pays": pays,
              if (nomEntreprise != null && nomEntreprise.trim().isNotEmpty)
                "nom_entreprise": nomEntreprise.trim(),
              if (email != null && email.trim().isNotEmpty)
                "email": email.trim(),
            }),
          )
          // Même raison que login() : l'inscription hache le mot de passe
          // côté Django (même coût PBKDF2).
          .timeout(const Duration(seconds: 20));

      Map<String, dynamic> body = {};
      if (response.body.isNotEmpty) {
        try {
          body = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          body = {};
        }
      }

      if (response.statusCode == 201) {
        return {"success": true, "data": body};
      }

      return {
        "success": false,
        "message": _extractErrorMessage(body),
        "statusCode": response.statusCode,
      };
    } on TimeoutException {
      return {
        "success": false,
        "message": "Délai dépassé. Vérifiez la connexion réseau.",
      };
    } on SocketException {
      return {
        "success": false,
        "message":
            "Serveur injoignable. Vérifiez l'URL API et que Django tourne sur le bon hôte/port.",
      };
    } catch (e) {
      return {"success": false, "message": "Erreur inattendue: $e"};
    }
  }

  static Future<Map<String, dynamic>> chauffeurLogin(
    String telephone,
    String code,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/chauffeur/login/"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"telephone": telephone, "code_acces": code}),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("STATUS CHAUFFEUR : ${response.statusCode}");
      debugPrint("REPONSE CHAUFFEUR : ${response.body}");

      Map<String, dynamic> body = {};
      if (response.body.isNotEmpty) {
        try {
          body = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          body = {};
        }
      }

      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": body,
          "message": "Connexion chauffeur réussie",
        };
      }

      return {
        "success": false,
        "message": _extractErrorMessage(body),
        "statusCode": response.statusCode,
      };
    } on TimeoutException {
      return {
        "success": false,
        "message": "Délai dépassé. Vérifiez la connexion réseau.",
      };
    } on SocketException {
      return {
        "success": false,
        "message":
            "Serveur injoignable. Vérifiez l'URL API et que Django tourne sur le bon hôte/port.",
      };
    } catch (e) {
      return {"success": false, "message": "Erreur inattendue: $e"};
    }
  }

  /// Ping de position envoyé périodiquement par le téléphone du chauffeur,
  /// indépendant de toute mission en cours — c'est ce qui permet à un
  /// camion redevenu disponible de rester localisable via son chauffeur.
  static Future<void> envoyerPositionChauffeur({
    required int chauffeurId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chauffeur/$chauffeurId/position/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('STATUS POSITION CHAUFFEUR : ${response.statusCode}');
    } catch (e) {
      // Un ping raté (réseau coupé, timeout...) ne doit jamais interrompre
      // le chauffeur : le suivant réessaiera de lui-même.
      debugPrint('Erreur envoi position chauffeur : $e');
    }
  }

  static Future<List<dynamic>> getChauffeurMissions(int chauffeurId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/chauffeur/$chauffeurId/missions/'))
          .timeout(const Duration(seconds: 10));

      debugPrint('STATUS MISSIONS CHAUFFEUR : ${response.statusCode}');
      debugPrint('REPONSE MISSIONS CHAUFFEUR : ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) {
          return body.cast<Map<String, dynamic>>();
        }
        return [];
      }

      throw Exception(_extractErrorMessage(jsonDecode(response.body)));
    } on TimeoutException {
      throw Exception('Délai dépassé. Vérifiez la connexion réseau.');
    } on SocketException {
      throw Exception(
        'Serveur injoignable. Vérifiez l\'URL API et que Django tourne sur le bon hôte/port.',
      );
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Démarre une mission (PLANIFIEE -> EN_COURS) depuis le tableau de bord
  /// du chauffeur. Ouvert par `chauffeurId`/`missionId`, sans JWT, comme le
  /// reste des endpoints chauffeur — l'appartenance à la mission est
  /// vérifiée côté Django (`chauffeur_demarrer_mission`).
  static Future<void> demarrerMissionChauffeur({
    required int chauffeurId,
    required int missionId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/chauffeur/$chauffeurId/missions/$missionId/demarrer/',
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return;

      throw Exception(_extractErrorMessage(jsonDecode(response.body)));
    } on TimeoutException {
      throw Exception('Délai dépassé. Vérifiez la connexion réseau.');
    } on SocketException {
      throw Exception(
        'Serveur injoignable. Vérifiez l\'URL API et que Django tourne sur le bon hôte/port.',
      );
    }
  }

  /// Termine une mission (EN_COURS -> TERMINEE) depuis le tableau de bord
  /// du chauffeur — même modèle d'autorisation que [demarrerMissionChauffeur].
  static Future<void> terminerMissionChauffeur({
    required int chauffeurId,
    required int missionId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/chauffeur/$chauffeurId/missions/$missionId/terminer/',
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return;

      throw Exception(_extractErrorMessage(jsonDecode(response.body)));
    } on TimeoutException {
      throw Exception('Délai dépassé. Vérifiez la connexion réseau.');
    } on SocketException {
      throw Exception(
        'Serveur injoignable. Vérifiez l\'URL API et que Django tourne sur le bon hôte/port.',
      );
    }
  }

  static Future<Map<String, dynamic>> getAuthenticatedJson(
    String endpoint, {
    String? token,
  }) async {
    final authToken = token ?? await StorageService.getToken();

    if (authToken == null || authToken.isEmpty) {
      throw Exception("Aucun token d'authentification disponible");
    }

    final response = await AuthenticatedHttp.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_extractErrorMessage(jsonDecode(response.body)));
  }

  Future<DashboardTransporteurModel> getDashboardTransporteur(
    String token,
  ) async {
    final response = await AuthenticatedHttp.get(
      Uri.parse("$baseUrl/transporteur/dashboard/"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return DashboardTransporteurModel.fromJson(jsonDecode(response.body));
    }

    throw Exception("Erreur chargement dashboard transporteur");
  }
}
