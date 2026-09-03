import 'package:flutter/material.dart';

import '../constants/pays_cedeao.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/admin_dashboard_model.dart';
import '../models/revenu_devise.dart';
import '../services/dashboard_service.dart';
import '../services/token_refresh_scheduler.dart';
import '../utils/responsive.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/theme_switcher.dart';
import 'admin/admin_camions_screen.dart';
import 'admin/admin_chauffeurs_screen.dart';
import 'admin/admin_demandes_screen.dart';
import 'admin/admin_litiges_screen.dart';
import 'admin/admin_missions_screen.dart';
import 'admin/admin_paiements_screen.dart';
import 'admin/admin_utilisateurs_screen.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

class DashboardAdmin extends StatefulWidget {
  final Map<String, dynamic> user;

  final String token;

  const DashboardAdmin({super.key, required this.user, required this.token});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  AdminDashboardModel? dashboard;
  bool loading = true;
  String? erreur;
  late String _token;

  @override
  void initState() {
    super.initState();
    _token = widget.token;
    TokenRefreshScheduler.start(
      onRefreshed: (nouveauToken) => setState(() => _token = nouveauToken),
    );
    chargerDashboard();
  }

  @override
  void dispose() {
    TokenRefreshScheduler.stop();
    super.dispose();
  }

  Future<void> chargerDashboard() async {
    setState(() {
      loading = true;
      erreur = null;
    });

    try {
      final result = await DashboardService.getAdminDashboard(_token);

      if (mounted) {
        setState(() {
          dashboard = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          erreur = '$e'.replaceFirst('Exception: ', '');
          loading = false;
        });
      }
    }
  }

  // Callbacks de navigation extraits une fois : partagés entre les cartes de
  // statistique (mobile/tablette/desktop) et les raccourcis de la sidebar
  // (tablette/desktop) pour ne jamais dupliquer la logique de push.
  void _ouvrirTransporteurs() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AdminUtilisateursScreen(
        token: widget.token,
        typeCompte: 'TRANSPORTEUR',
      ),
    ),
  );

  void _ouvrirEntreprises() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AdminUtilisateursScreen(
        token: widget.token,
        typeCompte: 'ENTREPRISE',
      ),
    ),
  );

  void _ouvrirChauffeurs() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AdminChauffeursScreen(token: widget.token),
    ),
  );

  void _ouvrirCamions() => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AdminCamionsScreen(token: widget.token)),
  );

  void _ouvrirMissions() => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AdminMissionsScreen(token: widget.token)),
  );

  void _ouvrirDemandes() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          AdminDemandesScreen(token: widget.token, initialFilter: 'OUVERTE'),
    ),
  );

  void _ouvrirPaiements() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AdminPaiementsScreen(token: widget.token),
    ),
  );

  void _ouvrirLitiges() => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AdminLitigesScreen(token: widget.token)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final appBar = AppBar(
      title: Text(l10n.adminTitle),
      actions: [
        const ThemeSwitcher(light: true),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: chargerDashboard,
        ),
      ],
    );

    final corps = loading
        ? const Center(child: CircularProgressIndicator())
        : erreur != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 52,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 14),
                  Text(erreur!, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: chargerDashboard,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRetry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bleuNuit,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: chargerDashboard,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _EnTeteAdmin(
                  nom: (widget.user["username"] ?? l10n.adminDefaultName)
                      .toString(),
                ),
                const SizedBox(height: 22),

                _TitreSection(l10n.adminAccountsSection),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: [
                    _StatCard(
                      icon: Icons.local_shipping_rounded,
                      titre: l10n.adminTransporteurs,
                      valeur: "${dashboard?.transporteursTotal ?? 0}",
                      couleur: _bleuAccent,
                      onTap: _ouvrirTransporteurs,
                    ),
                    _StatCard(
                      icon: Icons.business_rounded,
                      titre: l10n.adminEntreprises,
                      valeur: "${dashboard?.entreprisesTotal ?? 0}",
                      couleur: const Color(0xFF8B5CF6),
                      onTap: _ouvrirEntreprises,
                    ),
                    _StatCard(
                      icon: Icons.badge_rounded,
                      titre: l10n.adminChauffeurs,
                      valeur: "${dashboard?.chauffeursTotal ?? 0}",
                      couleur: const Color(0xFFF59E0B),
                      onTap: _ouvrirChauffeurs,
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                _TitreSection(l10n.adminFleetSection),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      icon: Icons.local_shipping_outlined,
                      titre: l10n.adminCamions,
                      valeur: "${dashboard?.camionsTotal ?? 0}",
                      couleur: _bleuNuit,
                      onTap: _ouvrirCamions,
                    ),
                    _StatCard(
                      icon: Icons.check_circle_rounded,
                      titre: l10n.adminAvailable,
                      valeur: "${dashboard?.camionsDisponibles ?? 0}",
                      couleur: const Color(0xFF34D399),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminCamionsScreen(
                            token: widget.token,
                            initialFilter: 'DISPONIBLE',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                _TitreSection(l10n.adminMissionsSection),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: [
                    _StatCard(
                      icon: Icons.assignment_rounded,
                      titre: l10n.adminTotal,
                      valeur: "${dashboard?.missionsTotal ?? 0}",
                      couleur: _bleuAccent,
                      onTap: _ouvrirMissions,
                    ),
                    _StatCard(
                      icon: Icons.local_shipping_rounded,
                      titre: l10n.adminEnCours,
                      valeur: "${dashboard?.missionsEnCours ?? 0}",
                      couleur: const Color(0xFFF59E0B),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminMissionsScreen(
                            token: widget.token,
                            initialFilter: 'EN_COURS',
                          ),
                        ),
                      ),
                    ),
                    _StatCard(
                      icon: Icons.check_rounded,
                      titre: l10n.adminTerminees,
                      valeur: "${dashboard?.missionsTerminees ?? 0}",
                      couleur: const Color(0xFF34D399),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminMissionsScreen(
                            token: widget.token,
                            initialFilter: 'TERMINEE',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                _TitreSection(l10n.adminMarketSection),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      icon: Icons.campaign_outlined,
                      titre: l10n.adminOpenRequests,
                      valeur: "${dashboard?.demandesOuvertes ?? 0}",
                      couleur: const Color(0xFF8B5CF6),
                      onTap: _ouvrirDemandes,
                    ),
                    _StatCard(
                      icon: Icons.payments_rounded,
                      titre: l10n.adminRevenue,
                      valeur: _valeurRevenus(
                        dashboard?.revenusTotal ?? const [],
                      ),
                      complement: _complementRevenus(
                        l10n,
                        dashboard?.revenusTotal ?? const [],
                      ),
                      couleur: const Color(0xFF34D399),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminMissionsScreen(
                            token: widget.token,
                            initialFilter: 'TERMINEE',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                _TitreSection(l10n.adminPaiementsTitle),
                const SizedBox(height: 10),
                _CarteAction(
                  icone: Icons.task_alt_rounded,
                  texte: l10n.adminPaiementsTitle,
                  onTap: _ouvrirPaiements,
                ),
                const SizedBox(height: 12),
                _CarteAction(
                  icone: Icons.gavel_rounded,
                  texte: l10n.adminLitigesTitle,
                  onTap: _ouvrirLitiges,
                ),
              ],
            ),
          );

    final formFactor = formFactorOf(context);
    if (formFactor == FormFactor.mobile) {
      return Scaffold(
        appBar: appBar,
        body: corps,
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          AppSidebar(
            etendue: formFactor == FormFactor.desktop,
            items: [
              AppSidebarItem(
                icon: Icons.local_shipping_rounded,
                label: l10n.adminTransporteurs,
                selected: false,
                onTap: _ouvrirTransporteurs,
              ),
              AppSidebarItem(
                icon: Icons.business_rounded,
                label: l10n.adminEntreprises,
                selected: false,
                onTap: _ouvrirEntreprises,
              ),
              AppSidebarItem(
                icon: Icons.badge_rounded,
                label: l10n.adminChauffeurs,
                selected: false,
                onTap: _ouvrirChauffeurs,
              ),
              AppSidebarItem(
                icon: Icons.local_shipping_outlined,
                label: l10n.adminCamions,
                selected: false,
                onTap: _ouvrirCamions,
              ),
              AppSidebarItem(
                icon: Icons.assignment_rounded,
                label: l10n.adminMissionsSection,
                selected: false,
                onTap: _ouvrirMissions,
              ),
              AppSidebarItem(
                icon: Icons.campaign_outlined,
                label: l10n.adminOpenRequests,
                selected: false,
                onTap: _ouvrirDemandes,
              ),
              AppSidebarItem(
                icon: Icons.task_alt_rounded,
                label: l10n.adminPaiementsTitle,
                selected: false,
                onTap: _ouvrirPaiements,
              ),
              AppSidebarItem(
                icon: Icons.gavel_rounded,
                label: l10n.adminLitigesTitle,
                selected: false,
                onTap: _ouvrirLitiges,
              ),
            ],
          ),
          Expanded(
            child: BoundedContent(
              padding: const EdgeInsets.all(8),
              child: corps,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteAction extends StatelessWidget {
  final IconData icone;
  final String texte;
  final VoidCallback onTap;

  const _CarteAction({
    required this.icone,
    required this.texte,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icone, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texte,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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

class _TitreSection extends StatelessWidget {
  final String texte;

  const _TitreSection(this.texte);

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _EnTeteAdmin extends StatelessWidget {
  final String nom;

  const _EnTeteAdmin({required this.nom});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_bleuNuit, _bleuAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminGreeting(nom),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.adminOverview,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

/// Devise dominante formatée (première entrée : la liste est déjà triée par
/// montant décroissant côté backend), affichée en `valeur` de la carte
/// Revenus. `'0'` si la plateforme n'a encore aucune mission terminée.
String _valeurRevenus(List<RevenuDevise> revenus) {
  if (revenus.isEmpty) return '0';
  final dominant = revenus.first;
  return formatMontant(dominant.montant, dominant.devise);
}

/// Indicateur "+N autres devises" affiché sous la valeur quand la carte
/// Revenus doit rester compacte — `null` si tous les revenus sont dans une
/// seule devise (rien à indiquer).
String? _complementRevenus(AppLocalizations l10n, List<RevenuDevise> revenus) {
  final autres = revenus.length - 1;
  if (autres <= 0) return null;
  return autres == 1
      ? l10n.adminOtherCurrency
      : l10n.adminOtherCurrencies(autres);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String valeur;
  final Color couleur;
  final String? complement;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.titre,
    required this.valeur,
    required this.couleur,
    this.complement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contenu = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: couleur, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                valeur,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                titre,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (complement != null)
                Text(
                  complement!,
                  style: TextStyle(
                    color: couleur,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          // Chevron discret : signale qu'une carte mène à un écran de détail,
          // sans surcharger la mise en page compacte de la grille.
          if (onTap != null)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return contenu;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: contenu,
    );
  }
}
