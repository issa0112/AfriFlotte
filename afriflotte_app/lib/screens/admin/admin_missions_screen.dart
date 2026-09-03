import 'package:flutter/material.dart';

import '../../constants/pays_cedeao.dart';
import '../../constants/statut_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/mission.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_entity_list.dart';

const _bleuFonce = Color(0xFF071A3A);
const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Vue admin plateforme de toutes les missions, tous clients/transporteurs
/// confondus (`GET /admin/missions/`) — ouverte depuis les cartes
/// "Missions"/"En cours"/"Terminées"/"Revenus" du tableau de bord admin.
/// `initialFilter` respecte les mêmes clés que `MissionsClientScreen`.
class AdminMissionsScreen extends StatefulWidget {
  final String token;
  final String? initialFilter;

  const AdminMissionsScreen({
    super.key,
    required this.token,
    this.initialFilter,
  });

  @override
  State<AdminMissionsScreen> createState() => _AdminMissionsScreenState();
}

class _AdminMissionsScreenState extends State<AdminMissionsScreen> {
  late Future<List<Mission>> _future;
  late String _filtre;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _filtre = widget.initialFilter ?? 'TOUTES';
    _future = AdminService.getMissions(widget.token);
  }

  Future<void> _rafraichir() async {
    final future = AdminService.getMissions(widget.token);
    setState(() => _future = future);
    await future.catchError((_) => <Mission>[]);
  }

  List<Mission> _filtrer(List<Mission> liste) {
    var resultat = _filtre == 'TOUTES'
        ? liste
        : liste.where((m) => m.statut.toUpperCase() == _filtre).toList();
    final terme = _recherche.trim().toLowerCase();
    if (terme.isNotEmpty) {
      resultat = resultat
          .where(
            (m) =>
                m.trajet.toLowerCase().contains(terme) ||
                (m.clientNom ?? '').toLowerCase().contains(terme) ||
                m.transporteurNom.toLowerCase().contains(terme),
          )
          .toList();
    }
    return resultat;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtres = <String, String>{
      'TOUTES': l10n.missionsClientFilterAll,
      'PLANIFIEE': l10n.missionsClientFilterPlanifiee,
      'EN_COURS': l10n.missionsClientFilterEnCours,
      'TERMINEE': l10n.missionsClientFilterTerminee,
      'ANNULEE': l10n.missionsClientFilterAnnulee,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bleuFonce, _bleuNuit],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          l10n.adminMissionsTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _BarreRecherche(
                      hint: l10n.adminSearchHint,
                      onChanged: (v) => setState(() => _recherche = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: filtres.entries.map((entry) {
                  final actif = entry.key == _filtre;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: actif,
                      onSelected: (_) => setState(() => _filtre = entry.key),
                      label: Text(entry.value),
                      labelStyle: TextStyle(
                        color: actif ? Colors.white : _bleuNuit,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      selectedColor: _bleuAccent,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide(
                        color: actif ? _bleuAccent : Colors.grey.shade300,
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Mission>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _EtatErreur(
                    message: '${snapshot.error}'.replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    onRetry: _rafraichir,
                  );
                }

                final missions = _filtrer(snapshot.data ?? const []);

                if (missions.isEmpty) {
                  return _EtatVide(
                    message: l10n.adminMissionsEmpty,
                    rechercheActive: _recherche.isNotEmpty,
                    l10n: l10n,
                  );
                }

                return ResponsiveEntityList<Mission>(
                  items: missions,
                  onRefresh: _rafraichir,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  mobileCardBuilder: (context, mission) =>
                      _CarteMission(mission: mission),
                  columns: [
                    TableColumn<Mission>(
                      label: l10n.tableColonneTrajet,
                      sortBy: (a, b) => a.trajet.compareTo(b.trajet),
                      cell: (m) => DataCell(Text(m.trajet)),
                    ),
                    TableColumn<Mission>(
                      label: l10n.tableColonneClient,
                      sortBy: (a, b) =>
                          (a.clientNom ?? '').compareTo(b.clientNom ?? ''),
                      cell: (m) => DataCell(Text(m.clientNom ?? '—')),
                    ),
                    TableColumn<Mission>(
                      label: l10n.tableColonneTransporteur,
                      sortBy: (a, b) =>
                          a.transporteurNom.compareTo(b.transporteurNom),
                      cell: (m) => DataCell(Text(m.transporteurNom)),
                    ),
                    TableColumn<Mission>(
                      label: l10n.tableColonneStatut,
                      cell: (m) => DataCell(_badgeStatutMission(m)),
                    ),
                    TableColumn<Mission>(
                      label: l10n.tableColonneMontant,
                      numeric: true,
                      sortBy: (a, b) =>
                          (a.prixFinal ?? 0).compareTo(b.prixFinal ?? 0),
                      cell: (m) =>
                          DataCell(Text(formatMontant(m.prixFinal, m.devise))),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarreRecherche extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _BarreRecherche({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _EtatErreur extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _EtatErreur({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).commonRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: _bleuNuit,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  final String message;
  final bool rechercheActive;
  final AppLocalizations l10n;

  const _EtatVide({
    required this.message,
    required this.rechercheActive,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              rechercheActive
                  ? Icons.search_off_rounded
                  : Icons.assignment_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              rechercheActive ? l10n.adminNoResults : message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _badgeStatutMission(Mission mission) {
  final couleur = couleurStatut(mission.statut);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: couleur.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      mission.statutLibelle,
      style: TextStyle(
        color: couleur,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    ),
  );
}

class _CarteMission extends StatelessWidget {
  final Mission mission;

  const _CarteMission({required this.mission});

  @override
  Widget build(BuildContext context) {
    final couleur = couleurStatut(mission.statut);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  mission.statutLibelle,
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.business_outlined,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  mission.clientNom ?? '—',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  mission.transporteurNom,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
              ),
              Text(
                formatMontant(mission.prixFinal, mission.devise),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: _bleuNuit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
