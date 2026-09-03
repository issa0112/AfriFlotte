import 'package:flutter/material.dart';

import '../../constants/pays_cedeao.dart';
import '../../constants/statut_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/mission.dart';
import '../../models/paiement.dart';
import '../../services/mission_service.dart';
import '../../services/paiement_service.dart';
import '../paiement/choisir_mode_paiement_screen.dart';
import '../paiement/historique_paiements_screen.dart';

/// Missions du client : les demandes qui ont trouvé un transporteur.
/// Utilisable en onglet (embedded) ou poussée en plein écran.
class MissionsClientScreen extends StatefulWidget {
  final String token;
  final bool embedded;

  // Filtre pré-sélectionné à l'ouverture, ex. depuis une carte du tableau de
  // bord ("Missions en cours" -> EN_COURS). Doit être une des clés de
  // `filtres` (voir build ci-dessous) ; null = 'TOUTES'.
  final String? initialFilter;

  const MissionsClientScreen({
    super.key,
    required this.token,
    this.embedded = false,
    this.initialFilter,
  });

  @override
  State<MissionsClientScreen> createState() => _MissionsClientScreenState();
}

class _MissionsClientScreenState extends State<MissionsClientScreen> {
  late Future<List<Mission>> _futureMissions;
  late String _filtre;

  @override
  void initState() {
    super.initState();
    _filtre = widget.initialFilter ?? 'TOUTES';
    _futureMissions = MissionService.getMissions(widget.token);
  }

  Future<void> _refresh() async {
    final future = MissionService.getMissions(widget.token);
    // Bloc, pas flèche : voir liste_chauffeurs.dart._rafraichir pour le
    // pourquoi (setState() planterait, le callback "retournerait" le Future).
    setState(() {
      _futureMissions = future;
    });
    // On attend le résultat pour que le RefreshIndicator reste visible,
    // sans laisser remonter l'erreur (le FutureBuilder l'affiche déjà).
    await future.catchError((_) => <Mission>[]);
  }

  List<Mission> _appliquerFiltre(List<Mission> missions) {
    if (_filtre == 'TOUTES') return missions;
    return missions
        .where((mission) => mission.statut.toUpperCase() == _filtre)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final filtres = <String, String>{
      'TOUTES': l10n.missionsClientFilterAll,
      'PLANIFIEE': l10n.missionsClientFilterPlanifiee,
      'EN_COURS': l10n.missionsClientFilterEnCours,
      'TERMINEE': l10n.missionsClientFilterTerminee,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.missionsClientTitle),
        backgroundColor: const Color(0xFF102C5C),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !widget.embedded,
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Mission>>(
        future: _futureMissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: '${snapshot.error}'.replaceFirst('Exception: ', ''),
              onRetry: _refresh,
            );
          }

          final missions = snapshot.data ?? const <Mission>[];
          final visibles = _appliquerFiltre(missions);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                _FiltreBar(
                  filtres: filtres,
                  selection: _filtre,
                  compteur: (cle) => cle == 'TOUTES'
                      ? missions.length
                      : missions
                            .where((m) => m.statut.toUpperCase() == cle)
                            .length,
                  onChanged: (cle) => setState(() => _filtre = cle),
                ),
                Expanded(
                  child: visibles.isEmpty
                      ? _EmptyState(
                          filtreActif: _filtre != 'TOUTES',
                          aDesMissions: missions.isNotEmpty,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: visibles.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => _MissionCard(
                            mission: visibles[index],
                            token: widget.token,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FiltreBar extends StatelessWidget {
  final Map<String, String> filtres;
  final String selection;
  final int Function(String) compteur;
  final ValueChanged<String> onChanged;

  const _FiltreBar({
    required this.filtres,
    required this.selection,
    required this.compteur,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: filtres.entries.map((entry) {
          final actif = entry.key == selection;
          final total = compteur(entry.key);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: actif,
              onSelected: (_) => onChanged(entry.key),
              label: Text('${entry.value} ($total)'),
              labelStyle: TextStyle(
                color: actif ? Colors.white : const Color(0xFF102C5C),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              selectedColor: const Color(0xFF2563EB),
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(
                color: actif ? const Color(0xFF2563EB) : Colors.grey.shade300,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission mission;
  final String token;

  const _MissionCard({required this.mission, required this.token});

  Color get _statutColor => couleurStatut(mission.statut);

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year}';
  }

  String _prix(AppLocalizations l10n) {
    final prix = mission.prixFinal;
    if (prix == null) return l10n.missionsClientPrixNonConfirme;
    return formatMontant(prix, mission.devise);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.trajet,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statutColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  mission.statutLibelle,
                  style: TextStyle(
                    color: _statutColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Ligne(
            icon: Icons.public_outlined,
            label: l10n.missionsClientPaysLabel,
            value:
                '${nomParPays(mission.paysDepart) ?? mission.paysDepart} → ${nomParPays(mission.paysArrivee) ?? mission.paysArrivee}',
          ),
          _Ligne(
            icon: Icons.business_outlined,
            label: l10n.missionsClientTransporteurLabel,
            value: mission.transporteurNom,
          ),
          _Ligne(
            icon: Icons.inventory_2_outlined,
            label: l10n.missionsClientMarchandiseLabel,
            value: mission.produit,
          ),
          _Ligne(
            icon: Icons.local_shipping_outlined,
            label: l10n.missionsClientCamionsLabel,
            value: l10n.missionsClientCamionsValue(
              mission.nombreCamions,
              mission.typeCamion,
            ),
          ),
          _Ligne(
            icon: Icons.event_outlined,
            label: l10n.missionsClientChargementLabel,
            value: _formatDate(mission.dateChargement),
          ),
          _Ligne(
            icon: Icons.payments_outlined,
            label: l10n.missionsClientPrixLabel,
            value: _prix(l10n),
          ),
          if (mission.dateDepart != null || mission.dateArrivee != null) ...[
            const SizedBox(height: 4),
            Divider(color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _Jalon(
                    label: l10n.missionsClientDepart,
                    value: _formatDate(mission.dateDepart),
                    atteint: mission.dateDepart != null,
                  ),
                ),
                Expanded(
                  child: _Jalon(
                    label: l10n.missionsClientArrivee,
                    value: _formatDate(mission.dateArrivee),
                    atteint: mission.dateArrivee != null,
                  ),
                ),
              ],
            ),
          ],
          if (mission.prixFinal != null &&
              mission.statut.toUpperCase() != 'ANNULEE') ...[
            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade200),
            _PaiementFooter(mission: mission, token: token),
          ],
        ],
      ),
    );
  }
}

/// Zone paiement au pied de la carte mission : un appel réseau par carte
/// (pas de champ paiement embarqué dans `MissionSerializer`) — acceptable
/// tant que la liste de missions d'un client reste petite (pas de pagination
/// aujourd'hui) ; à revoir si ça devient un vrai volume.
class _PaiementFooter extends StatefulWidget {
  final Mission mission;
  final String token;

  const _PaiementFooter({required this.mission, required this.token});

  @override
  State<_PaiementFooter> createState() => _PaiementFooterState();
}

class _PaiementFooterState extends State<_PaiementFooter> {
  late Future<Paiement?> _future;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    _future = PaiementService.getPaiementMission(
      token: widget.token,
      missionId: widget.mission.id,
    );
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'SECURISE':
      case 'LIBERE':
        return const Color(0xFF0EA5E9);
      case 'VERSE':
        return const Color(0xFF16A34A);
      case 'REMBOURSE':
      case 'ECHEC':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<Paiement?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 4);
        }

        final paiement = snapshot.data;

        if (paiement == null) {
          return Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final resultat = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ChoisirModePaiementScreen(
                      token: widget.token,
                      mission: widget.mission,
                    ),
                  ),
                );
                if (resultat == true) setState(_charger);
              },
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: Text(l10n.paiementBouton),
            ),
          );
        }

        final couleur = _couleurStatut(paiement.statut);
        return Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaiementDetailScreen(
                    token: widget.token,
                    paiement: paiement,
                  ),
                ),
              );
              setState(_charger);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 16, color: couleur),
                const SizedBox(width: 6),
                Text(
                  paiement.statutLibelle,
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Ligne extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Ligne({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Jalon extends StatelessWidget {
  final String label;
  final String value;
  final bool atteint;

  const _Jalon({
    required this.label,
    required this.value,
    required this.atteint,
  });

  @override
  Widget build(BuildContext context) {
    final color = atteint ? const Color(0xFF34D399) : Colors.grey.shade400;

    return Row(
      children: [
        Icon(
          atteint ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool filtreActif;
  final bool aDesMissions;

  const _EmptyState({required this.filtreActif, required this.aDesMissions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final titre = filtreActif && aDesMissions
        ? l10n.missionsClientEmptyFiltered
        : l10n.missionsClientEmptyNone;

    final detail = filtreActif && aDesMissions
        ? l10n.missionsClientChangeFilter
        : l10n.missionsClientEmptyHint;

    // ListView : garde le RefreshIndicator utilisable même sans contenu.
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
      children: [
        Icon(
          Icons.local_shipping_outlined,
          size: 56,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          titre,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).commonRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
