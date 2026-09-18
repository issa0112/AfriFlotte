import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/auth_navigation.dart';
import 'auth/auth_screen.dart';
import 'chauffeur/chauffeur_dashboard_screen.dart';

const _bleuFonce = Color(0xFF071A3A);
const _bleuNuit = Color(0xFF102C5C);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _demarrer();
  }

  // Recharger la page (F5 sur le web) relance l'appli depuis main(), donc
  // depuis ce splash screen — sans ça, un token déjà valide en storage était
  // ignoré et l'utilisateur retombait systématiquement sur l'écran de
  // connexion au lieu de reprendre sur son tableau de bord.
  Future<void> _demarrer() async {
    final token = await StorageService.getToken();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      await _reprendreSessionChauffeur();
      return;
    }

    try {
      final user = await ApiService.getAuthenticatedJson(
        '/profil/',
        token: token,
      );

      if (!mounted) return;

      naviguerApresConnexion(context, user, token);
    } catch (_) {
      await StorageService.clear();

      if (!mounted) return;

      _allerVersConnexion();
    }
  }

  // Le compte chauffeur n'a pas de JWT (cf. `ChauffeurLoginView` côté
  // Django) : reprendre sa session au démarrage, c'est rejouer un login
  // silencieux avec le telephone+code_acces gardés par `AuthScreen` à la
  // connexion — exactement ce qu'un vrai login ferait, sans redemander le
  // code d'accès tant qu'il reste valide.
  Future<void> _reprendreSessionChauffeur() async {
    final session = await StorageService.getChauffeurSession();
    if (session == null) {
      _allerVersConnexion();
      return;
    }

    try {
      final resultat = await ApiService.chauffeurLogin(
        session.telephone,
        session.codeAcces,
      );

      if (!mounted) return;

      if (resultat["success"] != true) {
        await StorageService.clear();
        if (!mounted) return;
        _allerVersConnexion();
        return;
      }

      final data = resultat["data"] ?? {};
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ChauffeurDashboardScreen(
            chauffeur: {
              'id': data['chauffeur_id'],
              'nom': data['nom'],
              'photo': data['photo'],
              'code_acces': session.codeAcces,
            },
          ),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      // Panne réseau au démarrage, pas forcément un code d'accès devenu
      // invalide : contrairement à un rejet explicite du serveur, on ne
      // supprime pas la session pour laisser une reconnexion réussir au
      // prochain lancement.
      _allerVersConnexion();
    }
  }

  void _allerVersConnexion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bleuFonce,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bleuFonce, _bleuNuit],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                // ClipRRect : le logo a désormais un fond blanc plein (plus
                // de transparence), il lui faut ses propres coins arrondis
                // pour ne pas former un carré dur dans le cadre arrondi.
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset('assets/images/logo_icon.png'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "AfriFlotte",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context).splashTagline,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
