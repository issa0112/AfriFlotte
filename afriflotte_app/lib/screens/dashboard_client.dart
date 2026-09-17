import 'package:flutter/material.dart';

import '../constants/pays_cedeao.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/dashboard_client_model.dart';
import '../models/revenu_devise.dart';
import '../services/dashboard_service.dart';
import '../services/token_refresh_scheduler.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/theme_switcher.dart';
import 'client/compte_client_screen.dart';
import 'client/historique_client_screen.dart';
import 'client/missions_client_screen.dart';
import 'client/nouvelle_demande_screen.dart';
import 'client/profil_client_screen.dart';
import 'client/propositions_recues_screen.dart';
import 'client/recherche_camion_screen.dart';
import 'notifications_screen.dart';
import 'paiement/historique_paiements_screen.dart';

/// Index des onglets du client. Nommés pour que la navigation croisée
/// (carte d'accueil → onglet, création de demande → historique) reste lisible.
class ClientTab {
  static const accueil = 0;
  static const demande = 1;
  static const missions = 2;
  static const historique = 3;
  static const profil = 4;
}

class DashboardClient extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;

  const DashboardClient({super.key, required this.user, required this.token});

  @override
  State<DashboardClient> createState() => _DashboardClientState();
}

class _DashboardClientState extends State<DashboardClient> {
  int index = ClientTab.accueil;
  late String _token;
  late Map<String, dynamic> _user;

  // Filtre à appliquer au prochain affichage de l'onglet correspondant :
  // rempli quand une carte du tableau de bord ("Missions en cours",
  // "Demandes ouvertes", ...) navigue vers un onglet, remis à null pour un
  // tap classique sur la barre de navigation (donc plus de filtre implicite
  // qui resterait collé après une navigation "normale").
  String? _missionsFilter;
  String? _historiqueFilter;

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

  void _allerVers(int tab, {String? filtre}) {
    final filtreChange =
        (tab == ClientTab.missions && filtre != _missionsFilter) ||
        (tab == ClientTab.historique && filtre != _historiqueFilter);

    if (tab == index && !filtreChange) return;

    setState(() {
      index = tab;
      if (tab == ClientTab.missions) _missionsFilter = filtre;
      if (tab == ClientTab.historique) _historiqueFilter = filtre;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Les écrans ne sont pas conservés dans un IndexedStack : chaque retour
    // sur un onglet le remonte, donc relance son chargement API. C'est ce qui
    // permet à l'historique d'afficher une demande tout juste créée. Utilise
    // `_token` (pas `widget.token`) pour que le rafraîchissement en
    // arrière-plan (TokenRefreshScheduler) atteigne aussi les écrans déjà
    // montés au prochain rebuild, sans perdre leur état interne.
    final pages = [
      _ClientHome(
        user: _user,
        token: _token,
        onNavigate: _allerVers,
        onUtilisateurMisAJour: (u) => setState(() => _user = u),
      ),
      NouvelleDemandeScreen(
        token: _token,
        embedded: true,
        onCreated: () => _allerVers(ClientTab.historique),
      ),
      MissionsClientScreen(
        token: _token,
        embedded: true,
        initialFilter: _missionsFilter,
      ),
      HistoriqueClientScreen(
        token: _token,
        embedded: true,
        initialFilter: _historiqueFilter,
      ),
      ProfilClientScreen(
        user: _user,
        token: _token,
        onNavigate: _allerVers,
        onUtilisateurMisAJour: (u) => setState(() => _user = u),
      ),
    ];

    return AdaptiveShell(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      currentIndex: index,
      onTap: _allerVers,
      page: pages[index],
      items: [
        AdaptiveNavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: l10n.navHome,
        ),
        AdaptiveNavItem(
          icon: Icons.add_circle_outline,
          activeIcon: Icons.add_circle_rounded,
          label: l10n.navDemande,
        ),
        AdaptiveNavItem(
          icon: Icons.local_shipping_outlined,
          activeIcon: Icons.local_shipping_rounded,
          label: l10n.navMissions,
        ),
        AdaptiveNavItem(
          icon: Icons.history_outlined,
          activeIcon: Icons.history_rounded,
          label: l10n.navHistorique,
        ),
        AdaptiveNavItem(
          icon: Icons.badge_outlined,
          activeIcon: Icons.badge_rounded,
          label: l10n.navProfil,
        ),
      ],
    );
  }
}

class _ClientHome extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;
  final void Function(int tab, {String? filtre}) onNavigate;
  final ValueChanged<Map<String, dynamic>> onUtilisateurMisAJour;

  const _ClientHome({
    required this.user,
    required this.token,
    required this.onNavigate,
    required this.onUtilisateurMisAJour,
  });

  @override
  State<_ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<_ClientHome> {
  DashboardClientModel? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerDashboard();
  }

  Future<void> _chargerDashboard() async {
    try {
      final result = await DashboardService.getClientDashboard(widget.token);
      if (mounted) {
        setState(() {
          _dashboard = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = widget.user;
    final token = widget.token;
    final onNavigate = widget.onNavigate;

    final name = (user['nom_entreprise'] ?? user['username'] ?? 'Client')
        .toString();

    return Container(
      decoration: const BoxDecoration(
        // Dégradé vertical (pas diagonal) : au niveau de la barre de nav
        // flottante tout en bas, la couleur doit être uniforme sur toute la
        // largeur pour raccorder exactement avec le bleu uni de la barre
        // (`_navyMid` dans LiquidBottomNav, identique à 0xFF102C5C) — en
        // diagonal, seul le coin bas-droit atteignait cette teinte, le
        // reste de la barre tranchait sur un fond encore plus sombre.
        gradient: LinearGradient(
          colors: [Color(0xFF071A3A), Color(0xFF102C5C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      // `bottom: false` : avec `Scaffold(extendBody: true)`, un SafeArea
      // classique récupère un `MediaQuery.padding.bottom` artificiellement
      // égal à la hauteur de LiquidBottomNav et réserve cet espace — le
      // contenu ne peut alors jamais défiler jusqu'à la zone qui passe
      // derrière la barre. Le ScrollView gère déjà son propre padding bas
      // (100) pour ne pas finir sous la barre.
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.clientHomeGreeting(name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const ThemeSwitcher(light: true),
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NotificationsScreen(
                            token: token,
                            estTransporteur: false,
                          ),
                        ),
                      );
                      // Le compteur ne se met pas à jour tout seul en
                      // revenant : les notifs consultées entre-temps ont pu
                      // passer "lues" côté serveur (cf. dashboard_transporteur.
                      // dart, même pattern).
                      _chargerDashboard();
                    },
                    icon: Badge(
                      label: Text('${_dashboard?.notificationsNonLues ?? 0}'),
                      isLabelVisible:
                          (_dashboard?.notificationsNonLues ?? 0) > 0,
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.clientHomeSubtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          onNavigate(ClientTab.historique, filtre: 'OUVERTE'),
                      child: _StatMini(
                        icon: Icons.campaign_outlined,
                        valeur: '${_dashboard?.demandesOuvertes ?? 0}',
                        libelle: l10n.clientHomeOpenRequests,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          onNavigate(ClientTab.missions, filtre: 'EN_COURS'),
                      child: _StatMini(
                        icon: Icons.local_shipping_outlined,
                        valeur: '${_dashboard?.missionsEnCours ?? 0}',
                        libelle: l10n.clientHomeMissionsEnCours,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          onNavigate(ClientTab.missions, filtre: 'TERMINEE'),
                      child: _StatMini(
                        icon: Icons.task_alt_outlined,
                        valeur: '${_dashboard?.missionsTerminees ?? 0}',
                        libelle: l10n.clientHomeMissionsTerminees,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PropositionsRecuesScreen(token: token),
                        ),
                      ),
                      child: _StatMini(
                        icon: Icons.pending_actions_outlined,
                        valeur: '${_dashboard?.propositionsEnAttente ?? 0}',
                        libelle: l10n.clientHomePropositionsReceived,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _CarteDepense(
                depenses: _dashboard?.depensesTotal ?? const [],
                depensesMois: _dashboard?.depensesMois ?? const [],
              ),
              const SizedBox(height: 20),
              _PanelCard(
                title: l10n.clientHomeNewRequestTitle,
                subtitle: l10n.clientHomeNewRequestSubtitle,
                icon: Icons.add_circle_outline,
                color: const Color(0xFF38BDF8),
                onTap: () => onNavigate(ClientTab.demande),
              ),
              const SizedBox(height: 12),
              _PanelCard(
                title: l10n.clientHomePropositionsReceived,
                subtitle: l10n.clientHomePropositionsSubtitle,
                icon: Icons.local_offer_outlined,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PropositionsRecuesScreen(token: token),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _PanelCard(
                title: l10n.clientHomeMissionsTitle,
                subtitle: l10n.clientHomeMissionsSubtitle,
                icon: Icons.local_shipping_outlined,
                color: const Color(0xFF34D399),
                onTap: () => onNavigate(ClientTab.missions),
              ),
              const SizedBox(height: 12),
              _PanelCard(
                title: l10n.clientHomeHistoryTitle,
                subtitle: l10n.clientHomeHistorySubtitle,
                icon: Icons.history_outlined,
                color: const Color(0xFFF59E0B),
                onTap: () => onNavigate(ClientTab.historique),
              ),
              const SizedBox(height: 12),
              _PanelCard(
                title: l10n.clientHomeNearbyTitle,
                subtitle: l10n.clientHomeNearbySubtitle,
                icon: Icons.near_me_outlined,
                color: const Color(0xFF22D3EE),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RechercheCamionScreen(token: token),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _PanelCard(
                title: l10n.paiementHistoriqueTitle,
                subtitle: l10n.paiementHistoriqueSubtitle,
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF16A34A),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HistoriquePaiementsScreen(token: token),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _PanelCard(
                title: l10n.clientHomeCompanySpaceTitle,
                subtitle: l10n.clientHomeCompanySpaceSubtitle,
                icon: Icons.business_outlined,
                color: const Color(0xFFA78BFA),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CompteClientScreen(
                        user: user,
                        token: token,
                        onUtilisateurMisAJour: widget.onUtilisateurMisAJour,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PanelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tuile de statistique compacte pour l'accueil client, alimentée par
/// `ClientDashboardModel` (`/api/client/dashboard/`) — même DNA visuelle que
/// `_PanelCard` (fond blanc translucide sur le dégradé) plutôt que le style
/// `_StatCard` du dashboard transporteur, pensé lui pour un fond clair.
class _StatMini extends StatelessWidget {
  final IconData icon;
  final String valeur;
  final String libelle;

  const _StatMini({
    required this.icon,
    required this.valeur,
    required this.libelle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valeur,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  libelle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pendant client de `_CarteRevenu` (dashboard_transporteur.dart) — même
/// logique d'affichage (une ligne par devise via `formatMontant`, cf.
/// `RevenuDevise`/`revenus_par_devise` côté Django), mais adaptée au fond
/// dégradé sombre de `_ClientHome` : container translucide comme
/// `_PanelCard`/`_StatMini` plutôt que la carte blanche opaque du
/// transporteur, pensée elle pour un fond clair.
class _CarteDepense extends StatelessWidget {
  final List<RevenuDevise> depenses;
  final List<RevenuDevise> depensesMois;

  const _CarteDepense({required this.depenses, required this.depensesMois});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.payments_rounded, color: Color(0xFF34D399)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (depenses.isEmpty)
                  const Text(
                    '0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  // Une ligne par devise : un client CEDEAO peut avoir des
                  // missions terminées dans plusieurs pays/devises.
                  for (final d in depenses)
                    Text(
                      formatMontant(d.montant, d.devise),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                const SizedBox(height: 2),
                Text(
                  l10n.clientHomeTotalExpenses,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                  ),
                ),
                if (depensesMois.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.clientHomeExpensesThisMonth(
                      depensesMois
                          .map((d) => formatMontant(d.montant, d.devise))
                          .join(' · '),
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
