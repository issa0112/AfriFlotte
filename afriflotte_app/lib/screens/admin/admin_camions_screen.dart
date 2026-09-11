import 'package:flutter/material.dart';

import '../../constants/pays_cedeao.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/camion.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_entity_list.dart';

const _bleuFonce = Color(0xFF071A3A);
const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Vue admin plateforme de tous les camions, tous transporteurs confondus
/// (`GET /admin/camions/`) — ouverte depuis les cartes "Camions"/"Disponibles"
/// du tableau de bord admin, `initialFilter` choisit le chip de départ (même
/// mécanique que `MissionsClientScreen.initialFilter`).
class AdminCamionsScreen extends StatefulWidget {
  final String token;
  final String? initialFilter;

  const AdminCamionsScreen({
    super.key,
    required this.token,
    this.initialFilter,
  });

  @override
  State<AdminCamionsScreen> createState() => _AdminCamionsScreenState();
}

class _AdminCamionsScreenState extends State<AdminCamionsScreen> {
  late Future<List<Camion>> _future;
  late String _filtre;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _filtre = widget.initialFilter ?? 'TOUS';
    _future = AdminService.getCamions(widget.token);
  }

  Future<void> _rafraichir() async {
    final future = AdminService.getCamions(widget.token);
    setState(() => _future = future);
    await future.catchError((_) => <Camion>[]);
  }

  List<Camion> _filtrer(List<Camion> liste) {
    var resultat = _filtre == 'DISPONIBLE'
        ? liste.where((c) => c.disponible).toList()
        : liste;
    final terme = _recherche.trim().toLowerCase();
    if (terme.isNotEmpty) {
      resultat = resultat
          .where(
            (c) =>
                c.immatriculation.toLowerCase().contains(terme) ||
                (c.proprietaireNom ?? '').toLowerCase().contains(terme) ||
                c.ville.toLowerCase().contains(terme),
          )
          .toList();
    }
    return resultat;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtres = <String, String>{
      'TOUS': l10n.adminCamionsFilterAll,
      'DISPONIBLE': l10n.adminCamionsFilterDispo,
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
                          l10n.adminCamionsTitle,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          Expanded(
            child: FutureBuilder<List<Camion>>(
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

                final camions = _filtrer(snapshot.data ?? const []);

                if (camions.isEmpty) {
                  return _EtatVide(
                    message: l10n.adminCamionsEmpty,
                    rechercheActive: _recherche.isNotEmpty,
                    l10n: l10n,
                  );
                }

                return ResponsiveEntityList<Camion>(
                  items: camions,
                  onRefresh: _rafraichir,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  mobileCardBuilder: (context, camion) =>
                      _CarteCamion(camion: camion),
                  columns: [
                    TableColumn<Camion>(
                      label: l10n.tableColonneImmatriculation,
                      sortBy: (a, b) =>
                          a.immatriculation.compareTo(b.immatriculation),
                      cell: (c) => DataCell(Text(c.immatriculation)),
                    ),
                    TableColumn<Camion>(
                      label: l10n.tableColonneTransporteur,
                      sortBy: (a, b) => (a.proprietaireNom ?? '').compareTo(
                        b.proprietaireNom ?? '',
                      ),
                      cell: (c) => DataCell(Text(c.proprietaireNom ?? '—')),
                    ),
                    TableColumn<Camion>(
                      label: l10n.tableColonneType,
                      cell: (c) => DataCell(Text(c.typeCamion)),
                    ),
                    TableColumn<Camion>(
                      label: l10n.tableColonneVille,
                      sortBy: (a, b) => a.ville.compareTo(b.ville),
                      cell: (c) => DataCell(
                        Text('${c.ville}, ${nomParPays(c.pays) ?? c.pays}'),
                      ),
                    ),
                    TableColumn<Camion>(
                      label: l10n.tableColonneStatut,
                      cell: (c) => DataCell(_badgeStatutCamion(c)),
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
                  : Icons.local_shipping_outlined,
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

Color _couleurStatutCamion(Camion camion) =>
    camion.disponible ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);

Widget _badgeStatutCamion(Camion camion) {
  final couleur = _couleurStatutCamion(camion);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: couleur.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      camion.disponible ? 'Disponible' : 'En mission',
      style: TextStyle(
        color: couleur,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    ),
  );
}

class _CarteCamion extends StatelessWidget {
  final Camion camion;

  const _CarteCamion({required this.camion});

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurStatutCamion(camion);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.local_shipping_rounded, color: couleur),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  camion.immatriculation,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  camion.proprietaireNom ?? '—',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${camion.typeCamion} · ${camion.ville}, ${nomParPays(camion.pays) ?? camion.pays}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              camion.disponible ? 'Disponible' : 'En mission',
              style: TextStyle(
                color: couleur,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
