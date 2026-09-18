import 'package:flutter/material.dart';

import '../screens/transporteur/transporteur_home.dart';
import '../screens/dashboard_client.dart';
import '../screens/dashboard_admin.dart';
import '../screens/agent/agent_home.dart';
import '../screens/legal/contrat_transporteur_gate_screen.dart';

/// Route vers le bon écran d'accueil selon `type_compte`, et purge tout
/// l'historique de navigation en dessous (login/inscription y compris) pour
/// qu'un retour arrière ne puisse jamais ramener à un écran d'authentification.
/// Utilisé après une connexion réussie, qu'elle vienne du login direct ou
/// de la connexion automatique qui suit une inscription.
void naviguerApresConnexion(
  BuildContext context,
  Map<String, dynamic> user,
  String token,
) {
  Widget destination;

  switch (user['type_compte']) {
    case 'TRANSPORTEUR':
      // Contrat de partenariat obligatoire (core/contrats.py) : un compte
      // inscrit avant son introduction, ou dont la version acceptée est
      // périmée, doit l'accepter avant d'accéder à son espace — cf.
      // `contrat_transporteur_accepte` renvoyé par `/api/profil/` et par la
      // connexion elle-même.
      destination = user['contrat_transporteur_accepte'] == true
          ? TransporteurHome(user: user, token: token)
          : ContratTransporteurGateScreen(user: user, token: token);
      break;

    case 'ENTREPRISE':
      destination = DashboardClient(user: user, token: token);
      break;

    case 'ADMIN':
      destination = DashboardAdmin(user: user, token: token);
      break;

    case 'AGENT':
      destination = AgentHome(user: user, token: token);
      break;

    default:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Type de compte inconnu')));
      return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => destination),
    (route) => false,
  );
}
