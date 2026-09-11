import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/chauffeur.dart';
import '../../services/admin_service.dart';
import '../../utils/telephone.dart';
import '../../widgets/responsive_entity_list.dart';

const _bleuFonce = Color(0xFF071A3A);
const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Vue admin plateforme de tous les chauffeurs, tous transporteurs confondus
/// (`GET /admin/chauffeurs/`) — ouverte depuis la carte "Chauffeurs" du
/// tableau de bord admin.
class AdminChauffeursScreen extends StatefulWidget {
  final String token;

  const AdminChauffeursScreen({super.key, required this.token});

  @override
  State<AdminChauffeursScreen> createState() => _AdminChauffeursScreenState();
}

class _AdminChauffeursScreenState extends State<AdminChauffeursScreen> {
  late Future<List<Chauffeur>> _future;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _future = AdminService.getChauffeurs(widget.token);
  }

  Future<void> _rafraichir() async {
    final future = AdminService.getChauffeurs(widget.token);
    setState(() => _future = future);
    await future.catchError((_) => <Chauffeur>[]);
  }

  List<Chauffeur> _filtrer(List<Chauffeur> liste) {
    final terme = _recherche.trim().toLowerCase();
    if (terme.isEmpty) return liste;
    return liste
        .where(
          (c) =>
              c.nom.toLowerCase().contains(terme) ||
              c.telephone.contains(terme) ||
              (c.transporteurNom ?? '').toLowerCase().contains(terme),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                          l10n.adminChauffeursTitle,
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
          Expanded(
            child: FutureBuilder<List<Chauffeur>>(
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

                final chauffeurs = _filtrer(snapshot.data ?? const []);

                if (chauffeurs.isEmpty) {
                  return _EtatVide(
                    message: l10n.adminChauffeursEmpty,
                    rechercheActive: _recherche.isNotEmpty,
                    l10n: l10n,
                  );
                }

                return ResponsiveEntityList<Chauffeur>(
                  items: chauffeurs,
                  onRefresh: _rafraichir,
                  mobileCardBuilder: (context, chauffeur) =>
                      _CarteChauffeur(chauffeur: chauffeur),
                  columns: [
                    TableColumn<Chauffeur>(
                      label: l10n.tableColonneNom,
                      sortBy: (a, b) => a.nom.compareTo(b.nom),
                      cell: (c) => DataCell(Text(c.nom)),
                    ),
                    TableColumn<Chauffeur>(
                      label: l10n.tableColonneTelephone,
                      cell: (c) => DataCell(
                        Text(formaterLocal(c.telephone, c.pays) ?? ''),
                      ),
                    ),
                    TableColumn<Chauffeur>(
                      label: l10n.tableColonneTransporteur,
                      sortBy: (a, b) => (a.transporteurNom ?? '').compareTo(
                        b.transporteurNom ?? '',
                      ),
                      cell: (c) => DataCell(Text(c.transporteurNom ?? '—')),
                    ),
                    TableColumn<Chauffeur>(
                      label: l10n.tableColonneStatut,
                      cell: (c) => DataCell(_badgeStatutChauffeur(c)),
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
              rechercheActive ? Icons.search_off_rounded : Icons.badge_outlined,
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

Color _couleurStatutChauffeur(Chauffeur chauffeur) => chauffeur.actif
    ? (chauffeur.disponible ? const Color(0xFF16A34A) : const Color(0xFFF59E0B))
    : Colors.grey;

String _libelleStatutChauffeur(Chauffeur chauffeur) => !chauffeur.actif
    ? 'Inactif'
    : (chauffeur.disponible ? 'Disponible' : 'En mission');

Widget _badgeStatutChauffeur(Chauffeur chauffeur) {
  final couleur = _couleurStatutChauffeur(chauffeur);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: couleur.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      _libelleStatutChauffeur(chauffeur),
      style: TextStyle(
        color: couleur,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    ),
  );
}

class _CarteChauffeur extends StatelessWidget {
  final Chauffeur chauffeur;

  const _CarteChauffeur({required this.chauffeur});

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurStatutChauffeur(chauffeur);
    final libelle = _libelleStatutChauffeur(chauffeur);

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
          CircleAvatar(
            radius: 24,
            backgroundColor: _bleuAccent.withValues(alpha: 0.12),
            backgroundImage: chauffeur.photo != null
                ? NetworkImage(chauffeur.photo!)
                : null,
            child: chauffeur.photo == null
                ? Text(
                    chauffeur.nom.isNotEmpty
                        ? chauffeur.nom[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: _bleuAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chauffeur.nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  chauffeur.transporteurNom ?? '—',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  formaterLocal(chauffeur.telephone, chauffeur.pays) ?? '',
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
              libelle,
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
