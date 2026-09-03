import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/token_refresh_scheduler.dart';
import '../../widgets/adaptive_shell.dart';
import 'dashboard_transporteur.dart';

import 'camions/liste_camions.dart';
import 'chauffeurs/liste_chauffeurs.dart';
import 'missions/mes_missions_screen.dart';
import 'gps/tracking_screen.dart';
import 'profil/profil_transporteur.dart';

class TransporteurHome extends StatefulWidget {
  final Map<String, dynamic> user;

  final String token;

  const TransporteurHome({super.key, required this.user, required this.token});

  @override
  State<TransporteurHome> createState() => _TransporteurHomeState();
}

class _TransporteurHomeState extends State<TransporteurHome> {
  int index = 0;

  late String _token;
  late Map<String, dynamic> _user;

  @override
  void initState() {
    super.initState();

    _token = widget.token;
    _user = widget.user;

    TokenRefreshScheduler.start(
      onRefreshed: (nouveauToken) => setState(() => _token = nouveauToken),
    );
  }

  @override
  void dispose() {
    TokenRefreshScheduler.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Reconstruit à chaque render (y compris après un rafraîchissement de
    // token en arrière-plan) : les écrans déjà montés récupèrent le token à
    // jour au prochain appel API sans perdre leur état interne — Flutter
    // réutilise le State tant que le type/la position dans l'arbre ne change
    // pas, seul `widget.token` change pour l'écran concerné.
    final pages = [
      DashboardTransporteur(user: _user, token: _token),

      ListeCamions(token: _token),

      ListeChauffeurs(token: _token),

      MesMissionsScreen(token: _token),

      GpsTransportScreen(token: _token),

      ProfilTransporteur(
        user: _user,
        token: _token,
        onProfilMisAJour: (utilisateurMisAJour) =>
            setState(() => _user = utilisateurMisAJour),
      ),
    ];

    return AdaptiveShell(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      currentIndex: index,
      onTap: (value) => setState(() => index = value),
      page: pages[index],
      items: [
        AdaptiveNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: l10n.navHome,
        ),
        AdaptiveNavItem(
          icon: Icons.local_shipping_outlined,
          activeIcon: Icons.local_shipping,
          label: l10n.navCamions,
        ),
        AdaptiveNavItem(
          icon: Icons.badge_outlined,
          activeIcon: Icons.badge,
          label: l10n.navChauffeurs,
        ),
        AdaptiveNavItem(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          label: l10n.navMissions,
        ),
        AdaptiveNavItem(
          icon: Icons.location_on_outlined,
          activeIcon: Icons.location_on,
          label: l10n.navGps,
        ),
        AdaptiveNavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: l10n.navProfil,
        ),
      ],
    );
  }
}
