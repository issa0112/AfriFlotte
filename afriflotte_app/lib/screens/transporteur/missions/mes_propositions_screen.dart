import 'package:flutter/material.dart';

import '../../../constants/statut_style.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/proposition.dart';
import '../../../services/proposition_service.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Propositions envoyées par le transporteur (`GET /api/propositions/`,
/// déjà filtré côté Django sur le transporteur connecté) — pendant en
/// lecture seule de `PropositionsRecuesScreen` côté entreprise : ici,
/// accepter/refuser n'est pas la main du transporteur, il ne fait que
/// suivre où en est chacune de ses propositions.
class MesPropositionsScreen extends StatefulWidget {
  final String token;

  // Proposition à mettre en évidence quand l'écran est ouvert depuis une
  // notification (NOUVELLE_DEMANDE ou PROPOSITION_REFUSEE) — même logique
  // que `PropositionsRecuesScreen.highlightId` côté entreprise.
  final int? highlightId;

  const MesPropositionsScreen({
    super.key,
    required this.token,
    this.highlightId,
  });

  @override
  State<MesPropositionsScreen> createState() => _MesPropositionsScreenState();
}

class _MesPropositionsScreenState extends State<MesPropositionsScreen> {
  late Future<List<Proposition>> _futurePropositions;
  late String _filtre;
  bool _absenceSignalee = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtre = widget.highlightId != null ? 'TOUTES' : 'EN_ATTENTE';
    _futurePropositions = PropositionService.getPropositions(widget.token);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _verifierPresenceHighlight(List<Proposition> propositions) {
    if (widget.highlightId == null || _absenceSignalee) return;
    if (propositions.any((p) => p.id == widget.highlightId)) return;

    _absenceSignalee = true;
    final l10n = AppLocalizations.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.propositionsRecuesHighlightNotFound)),
      );
    });
  }

  Future<void> _rafraichir() async {
    final future = PropositionService.getPropositions(widget.token);
    setState(() {
      _futurePropositions = future;
    });
    await future.catchError((_) => <Proposition>[]);
  }

  List<Proposition> _appliquerFiltre(List<Proposition> propositions) {
    var resultat = _filtre == 'TOUTES'
        ? propositions
        : propositions.where((p) => p.statut == _filtre).toList();

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      resultat = resultat
          .where(
            (p) =>
                p.trajet.toLowerCase().contains(query) ||
                (p.message?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    return resultat;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final filtres = <String, String>{
      'EN_ATTENTE': l10n.propositionsRecuesFilterEnAttente,
      'TOUTES': l10n.propositionsRecuesFilterAll,
      'ACCEPTEE': l10n.propositionsRecuesFilterAcceptee,
      'REFUSEE': l10n.propositionsRecuesFilterRefusee,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.mesPropositionsTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            onPressed: _rafraichir,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Proposition>>(
        future: _futurePropositions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: '${snapshot.error}'.replaceFirst('Exception: ', ''),
              onRetry: _rafraichir,
            );
          }

          final propositions = snapshot.data ?? const <Proposition>[];
          final visibles = _appliquerFiltre(propositions);
          _verifierPresenceHighlight(propositions);

          return RefreshIndicator(
            onRefresh: _rafraichir,
            child: Column(
              children: [
                _buildSearchField(),
                _FiltreBar(
                  filtres: filtres,
                  selection: _filtre,
                  compteur: (cle) => cle == 'TOUTES'
                      ? propositions.length
                      : propositions.where((p) => p.statut == cle).length,
                  onChanged: (cle) => setState(() => _filtre = cle),
                ),
                Expanded(
                  child: visibles.isEmpty
                      ? _EmptyState(
                          filtreActif: _filtre != 'TOUTES',
                          aDesPropositions: propositions.isNotEmpty,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: visibles.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => _PropositionCard(
                            proposition: visibles[index],
                            enEvidence:
                                widget.highlightId == visibles[index].id,
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
    );
  }
}

class _PropositionCard extends StatelessWidget {
  final Proposition proposition;
  final bool enEvidence;

  const _PropositionCard({required this.proposition, this.enEvidence = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final devise = proposition.devise ?? '';
    final couleur = couleurStatut(proposition.statut);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: enEvidence
            ? Border.all(color: _bleuAccent, width: 2)
            : Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: (enEvidence ? _bleuAccent : Colors.black).withValues(
              alpha: enEvidence ? 0.16 : 0.06,
            ),
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
                  proposition.trajet,
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
                  color: couleur.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  proposition.statutLibelle,
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.payments_outlined,
                label: '${proposition.prix.toStringAsFixed(0)} $devise'.trim(),
              ),
              _InfoChip(
                icon: Icons.local_shipping_outlined,
                label: l10n.propositionsRecuesCamionsValue(
                  proposition.camions.length,
                  proposition.typeCamion,
                ),
              ),
            ],
          ),
          if (proposition.message != null &&
              proposition.message!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              proposition.message!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool filtreActif;
  final bool aDesPropositions;

  const _EmptyState({
    required this.filtreActif,
    required this.aDesPropositions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final titre = filtreActif && aDesPropositions
        ? l10n.propositionsRecuesEmptyFiltered
        : l10n.mesPropositionsEmptyNone;

    final detail = filtreActif && aDesPropositions
        ? l10n.propositionsRecuesChangeFilter
        : l10n.mesPropositionsEmptyHint;

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
      children: [
        Icon(Icons.local_offer_outlined, size: 56, color: Colors.grey.shade400),
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
                backgroundColor: _bleuAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
