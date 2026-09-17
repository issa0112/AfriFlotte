import 'package:flutter/material.dart';

import '../../constants/pays_cedeao.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/dashboard_transporteur_model.dart';
import '../../models/revenu_devise.dart';
import '../../services/dashboard_service.dart';
import '../notifications_screen.dart';
import '../paiement/historique_paiements_screen.dart';
import '../../widgets/theme_switcher.dart';
import 'camions/liste_camions.dart';
import 'chauffeurs/liste_chauffeurs.dart';
import 'missions/demandes_disponibles.dart';
import 'missions/mes_propositions_screen.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

class DashboardTransporteur extends StatefulWidget {
  final Map<String, dynamic> user;

  final String token;

  const DashboardTransporteur({
    super.key,

    required this.user,

    required this.token,
  });

  @override
  State<DashboardTransporteur> createState() => _DashboardTransporteurState();
}

class _DashboardTransporteurState extends State<DashboardTransporteur> {
  DashboardTransporteurModel? dashboard;

  bool loading = true;

  @override
  void initState() {
    super.initState();

    chargerDashboard();
  }

  Future<void> chargerDashboard() async {
    try {
      final result = await DashboardService.getDashboard(widget.token);

      if (mounted) {
        setState(() {
          dashboard = result;

          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nom =
        (widget.user["nom_entreprise"] ??
                widget.user["username"] ??
                "Transporteur")
            .toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
      title: Text(l10n.dashTTitle),
        actions: [
          const ThemeSwitcher(light: true),
          IconButton(
            icon: Badge(
              label: Text('${dashboard?.notificationsNonLues ?? 0}'),
              isLabelVisible: (dashboard?.notificationsNonLues ?? 0) > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(
                    token: widget.token,
                    estTransporteur: true,
                  ),
                ),
              );
              chargerDashboard();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: chargerDashboard,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: chargerDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  _EnTeteCard(nom: nom),
                  const SizedBox(height: 22),
                  _TitreSection(l10n.dashTFleetSection),
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
                        icon: Icons.local_shipping_rounded,
                        titre: l10n.dashTCamions,
                        valeur: "${dashboard?.camionsTotal ?? 0}",
                        couleur: _bleuAccent,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ListeCamions(token: widget.token),
                            ),
                          );
                        },
                      ),
                      _StatCard(
                        icon: Icons.check_circle_rounded,
                        titre: l10n.dashTAvailable,
                        valeur: "${dashboard?.camionsDisponibles ?? 0}",
                        couleur: const Color(0xFF34D399),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ListeCamions(
                                token: widget.token,
                                initialFilter: 'DISPONIBLE',
                              ),
                            ),
                          );
                        },
                      ),
                      _StatCard(
                        icon: Icons.people_alt_rounded,
                        titre: l10n.dashTChauffeurs,
                        valeur: "${dashboard?.chauffeursTotal ?? 0}",
                        couleur: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ListeChauffeurs(token: widget.token),
                            ),
                          );
                        },
                      ),
                      _StatCard(
                        icon: Icons.pending_actions_rounded,
                        titre: l10n.dashTPropositions,
                        valeur: "${dashboard?.propositionsEnAttente ?? 0}",
                        couleur: const Color(0xFF8B5CF6),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MesPropositionsScreen(token: widget.token),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _CarteRevenu(
                    revenus: dashboard?.revenus ?? const [],
                    revenusMois: dashboard?.revenusMois ?? const [],
                  ),
                  const SizedBox(height: 22),
                  _CarteAction(
                    icone: Icons.campaign_outlined,
                    texte: l10n.dashTAvailableRequests,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              DemandesDisponibles(token: widget.token),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _CarteAction(
                    icone: Icons.local_offer_outlined,
                    texte: l10n.dashTMyPropositions,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MesPropositionsScreen(token: widget.token),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _CarteAction(
                    icone: Icons.receipt_long_outlined,
                    texte: l10n.paiementHistoriqueTitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              HistoriquePaiementsScreen(token: widget.token),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _TitreSection(l10n.dashTMissionsSection),
                  const SizedBox(height: 10),
                  _CarteStatutsMissions(dashboard: dashboard),
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

class _EnTeteCard extends StatelessWidget {
  final String nom;

  const _EnTeteCard({required this.nom});

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
                  l10n.dashTGreeting(nom),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.dashTTodaySummary,
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
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String valeur;
  final Color couleur;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.titre,
    required this.valeur,
    required this.couleur,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: couleur, size: 20),
          ),
          const Spacer(),
          Text(
            valeur,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            titre,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
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

class _CarteRevenu extends StatelessWidget {
  final List<RevenuDevise> revenus;
  final List<RevenuDevise> revenusMois;

  const _CarteRevenu({required this.revenus, required this.revenusMois});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.payments_rounded, color: Color(0xFF34D399)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (revenus.isEmpty)
                  const Text(
                    '0',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  )
                else
                  // Une ligne par devise : un transporteur CEDEAO peut avoir
                  // des missions terminées dans plusieurs pays/devises.
                  for (final r in revenus)
                    Text(
                      formatMontant(r.montant, r.devise),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                const SizedBox(height: 2),
                Text(
                  l10n.dashTTotalRevenue,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
                if (revenusMois.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.dashTRevenueThisMonth(
                      revenusMois
                          .map((r) => formatMontant(r.montant, r.devise))
                          .join(' · '),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          color: _bleuNuit,
          borderRadius: BorderRadius.circular(16),
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

class _CarteStatutsMissions extends StatelessWidget {
  final DashboardTransporteurModel? dashboard;

  const _CarteStatutsMissions({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final statuts = [
      (
        l10n.dashTPlanifiees,
        dashboard?.missionsPlanifiees ?? 0,
        const Color(0xFF2563EB),
      ),
      (
        l10n.dashTEnCours,
        dashboard?.missionsEnCours ?? 0,
        const Color(0xFFF59E0B),
      ),
      (
        l10n.dashTTerminees,
        dashboard?.missionsTerminees ?? 0,
        const Color(0xFF34D399),
      ),
      (
        l10n.dashTAnnulees,
        dashboard?.missionsAnnulees ?? 0,
        const Color(0xFFEF4444),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
      child: Column(
        children: [
          for (final (label, valeur, couleur) in statuts)
            // `Material` explicite : voir `_ActionTile` de
            // profil_transporteur.dart pour la raison (extendBody).
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: couleur,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  '$valeur',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: couleur,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
