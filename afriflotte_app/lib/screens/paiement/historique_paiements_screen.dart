import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/paiement.dart';
import '../../services/paiement_service.dart';

const _bleuNuit = Color(0xFF102C5C);

/// Historique des paiements du client/transporteur connecté
/// (`GET /mes-paiements/`) — accessible depuis le profil ou le tableau de
/// bord. Taper une carte ouvre le détail avec l'option de signaler un litige.
class HistoriquePaiementsScreen extends StatefulWidget {
  final String token;

  const HistoriquePaiementsScreen({super.key, required this.token});

  @override
  State<HistoriquePaiementsScreen> createState() =>
      _HistoriquePaiementsScreenState();
}

class _HistoriquePaiementsScreenState extends State<HistoriquePaiementsScreen> {
  late Future<List<Paiement>> _future;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = PaiementService.mesPaiements(widget.token);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _rafraichir() async {
    final future = PaiementService.mesPaiements(widget.token);
    setState(() => _future = future);
    await future.catchError((_) => <Paiement>[]);
  }

  Widget _buildSearchField() {
    return TextField(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.paiementHistoriqueTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildSearchField(),
          ),
          Expanded(
            child: FutureBuilder<List<Paiement>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final paiements = snapshot.data ?? const <Paiement>[];
                final query = _searchController.text.trim().toLowerCase();
                final visibles = query.isEmpty
                    ? paiements
                    : paiements
                          .where(
                            (p) => p.missionTrajet.toLowerCase().contains(query),
                          )
                          .toList();

                if (visibles.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _rafraichir,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 52,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          paiements.isEmpty
                              ? l10n.paiementHistoriqueEmpty
                              : 'Aucun résultat trouvé',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _rafraichir,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visibles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _PaiementCard(
                      paiement: visibles[index],
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaiementDetailScreen(
                              token: widget.token,
                              paiement: visibles[index],
                            ),
                          ),
                        );
                        _rafraichir();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaiementCard extends StatelessWidget {
  final Paiement paiement;
  final VoidCallback onTap;

  const _PaiementCard({required this.paiement, required this.onTap});

  Color _couleurStatut() {
    switch (paiement.statut) {
      case 'SECURISE':
      case 'LIBERE':
        return const Color(0xFF0EA5E9);
      case 'VERSE':
        return const Color(0xFF16A34A);
      case 'REMBOURSE':
      case 'ECHEC':
        return const Color(0xFFEF4444);
      case 'ENCAISSE':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurStatut();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  paiement.mode == 'CARTE'
                      ? Icons.credit_card_rounded
                      : Icons.payments_rounded,
                  color: couleur,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paiement.missionTrajet,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${paiement.montantTotal.toStringAsFixed(0)} ${paiement.devise}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
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
                  paiement.statutLibelle,
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Détail d'un paiement + bouton "Signaler un problème" (ouvre un `Litige`)
/// quand le paiement est dans un état contestable côté serveur
/// (`ouvrir_litige_service` re-valide de toute façon).
class PaiementDetailScreen extends StatefulWidget {
  final String token;
  final Paiement paiement;

  const PaiementDetailScreen({
    super.key,
    required this.token,
    required this.paiement,
  });

  @override
  State<PaiementDetailScreen> createState() => _PaiementDetailScreenState();
}

class _PaiementDetailScreenState extends State<PaiementDetailScreen> {
  bool _envoi = false;

  Future<void> _signalerProbleme() async {
    final l10n = AppLocalizations.of(context);
    final controleur = TextEditingController();

    final motif = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.paiementOuvrirLitige),
        content: TextField(
          controller: controleur,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.paiementMotifLitige,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controleur.text.trim()),
            child: Text(l10n.paiementEnvoyer),
          ),
        ],
      ),
    );

    if (motif == null || motif.isEmpty || !mounted) return;

    setState(() => _envoi = true);
    try {
      await PaiementService.ouvrirLitige(
        token: widget.token,
        paiementId: widget.paiement.id,
        motif: motif,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.paiementLitigeEnvoye)));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paiement = widget.paiement;
    final peutSignaler =
        ['ENCAISSE', 'SECURISE', 'LIBERE'].contains(paiement.statut) &&
        !paiement.aUnLitigeOuvert;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.paiementDetailTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paiement.missionTrajet,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _Ligne(
                  label: l10n.paiementMontantTotal,
                  valeur:
                      '${paiement.montantTotal.toStringAsFixed(0)} ${paiement.devise}',
                ),
                _Ligne(
                  label: l10n.paiementCommission(
                    paiement.commissionTaux.toStringAsFixed(0),
                  ),
                  valeur:
                      '${paiement.commissionMontant.toStringAsFixed(0)} ${paiement.devise}',
                ),
                _Ligne(
                  label: l10n.paiementNetTransporteur,
                  valeur:
                      '${paiement.montantTransporteur.toStringAsFixed(0)} ${paiement.devise}',
                ),
                _Ligne(label: 'Statut', valeur: paiement.statutLibelle),
                if (paiement.carteDernier4.isNotEmpty)
                  _Ligne(
                    label: 'Carte',
                    valeur:
                        '${paiement.carteMarque} •••• ${paiement.carteDernier4}'
                        '${paiement.carteExpiration.isNotEmpty ? ' (${paiement.carteExpiration})' : ''}',
                  ),
                if (paiement.referenceExterne.isNotEmpty)
                  _Ligne(label: 'Référence', valeur: paiement.referenceExterne),
              ],
            ),
          ),
          if (paiement.litiges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.adminLitigesTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final litige in paiement.litiges)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(litige.motif),
                    const SizedBox(height: 4),
                    Text(
                      litige.statutLibelle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (peutSignaler) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _envoi ? null : _signalerProbleme,
              icon: const Icon(Icons.flag_outlined),
              label: Text(l10n.paiementOuvrirLitige),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final String label;
  final String valeur;

  const _Ligne({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            valeur,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
