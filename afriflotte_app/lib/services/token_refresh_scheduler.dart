import 'dart:async';

import 'api_service.dart';

/// Rafraîchit périodiquement le token d'accès en arrière-plan pendant qu'un
/// écran d'accueil (transporteur/client/admin) reste monté, pour éviter à
/// l'utilisateur de se reconnecter toutes les 5 minutes (durée de vie du
/// token d'accès côté Django). Intervalle < 5 minutes pour rafraîchir avant
/// expiration, avec une marge confortable.
///
/// [start] doit être appelé depuis `initState()` de l'écran d'accueil et
/// [stop] depuis `dispose()`. [onRefreshed] reçoit le nouveau token à chaque
/// succès : l'appelant doit le stocker dans son propre état (`setState`) et
/// le repropager aux écrans enfants qu'il construit, `ApiService` n'ayant
/// pas de client HTTP central par lequel intercepter les appels existants.
///
/// Un seul minuteur à la fois : redémarrer annule l'ancien, il n'y a jamais
/// besoin de plusieurs minuteurs en parallèle (un seul écran d'accueil est
/// monté à la fois dans cette appli).
class TokenRefreshScheduler {
  static Timer? _timer;

  static void start({required void Function(String nouveauToken) onRefreshed}) {
    stop();

    _timer = Timer.periodic(const Duration(minutes: 4), (_) async {
      final nouveauToken = await ApiService.refreshAccessToken();

      if (nouveauToken != null) {
        onRefreshed(nouveauToken);
      }

      // Échec (refresh token expiré, ~1 jour par défaut, ou réseau coupé) :
      // volontairement silencieux, pas de reconnexion forcée en arrière-plan.
      // Le prochain appel API de l'utilisateur échouera avec un 401 normal.
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
