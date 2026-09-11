import 'dart:convert';

import 'package:flutter/material.dart';

import '../../constants/pays_cedeao.dart';
import '../../constants/statut_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/demande_transport.dart';
import '../../services/demande_transport_service.dart';
import 'nouvelle_demande_screen.dart';

/// Historique des demandes du client.
/// Utilisable en onglet (embedded) ou poussée en plein écran.
class HistoriqueClientScreen extends StatefulWidget {
  final String token;
  final bool embedded;

  // Filtre pré-sélectionné à l'ouverture, ex. depuis la carte "Demandes
  // ouvertes" du tableau de bord. Doit être une des clés de `filtres` (voir
  // build ci-dessous) ; null = 'TOUTES'.
  final String? initialFilter;

  const HistoriqueClientScreen({
    super.key,
    required this.token,
    this.embedded = false,
    this.initialFilter,
  });

  @override
  State<HistoriqueClientScreen> createState() => _HistoriqueClientScreenState();
}

class _HistoriqueClientScreenState extends State<HistoriqueClientScreen> {
  late Future<List<DemandeTransport>> _futureDemandes;
  late String _filtre;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtre = widget.initialFilter ?? 'TOUTES';
    _futureDemandes = DemandeTransportService.getDemandes(widget.token);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _refresh() async {
    final future = DemandeTransportService.getDemandes(widget.token);
    // Bloc, pas flèche : voir liste_chauffeurs.dart._rafraichir pour le
    // pourquoi (setState() planterait, le callback "retournerait" le Future).
    setState(() {
      _futureDemandes = future;
    });
    // L'erreur est déjà rendue par le FutureBuilder : on l'absorbe ici
    // pour ne pas casser le geste de pull-to-refresh.
    await future.catchError((_) => <DemandeTransport>[]);
  }

  Future<void> _modifier(DemandeTransport demande) async {
    final modifiee = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NouvelleDemandeScreen(token: widget.token, demande: demande),
      ),
    );

    if (modifiee == true) _refresh();
  }

  // Pas de vrai DELETE côté serveur (cf. DemandeDetailView : une demande déjà
  // vue par des transporteurs ne doit pas disparaître silencieusement) — on
  // passe son statut à ANNULEE via le PATCH déjà utilisé pour la
  // modification, ce qui la retire du marché et de la vue OUVERTE.
  Future<void> _supprimer(DemandeTransport demande) async {
    final l10n = AppLocalizations.of(context);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historiqueClientSupprimerConfirmTitle),
        content: Text(l10n.historiqueClientSupprimerConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.historiqueClientSupprimer),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      final response = await DemandeTransportService.modifierDemande(
        token: widget.token,
        demandeId: demande.id,
        data: {'statut': 'ANNULEE'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.historiqueClientSupprimerSuccess)),
        );
        _refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageErreur(response.body))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _messageErreur(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final detail = decoded['detail'] ?? decoded['statut'];
        if (detail != null) {
          return detail is List ? detail.first.toString() : detail.toString();
        }
      }
    } catch (_) {
      // Corps non JSON : on retombe sur le brut tronqué.
    }
    return body.length > 180 ? '${body.substring(0, 180)}…' : body;
  }

  List<DemandeTransport> _appliquerFiltre(List<DemandeTransport> demandes) {
    final query = _searchController.text.trim().toLowerCase();

    return demandes.where((demande) {
      final statutOk = _filtre == 'TOUTES' || demande.statut.toUpperCase() == _filtre;
      final texteOk =
          query.isEmpty ||
          demande.trajet.toLowerCase().contains(query) ||
          demande.produit.toLowerCase().contains(query);
      return statutOk && texteOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final filtres = <String, String>{
      'TOUTES': l10n.historiqueClientFilterAll,
      'OUVERTE': l10n.historiqueClientFilterOuverte,
      'EN_COURS': l10n.historiqueClientFilterEnCours,
      'TERMINEE': l10n.historiqueClientFilterTerminee,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.historiqueClientTitle),
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
      body: FutureBuilder<List<DemandeTransport>>(
        future: _futureDemandes,
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

          final demandes = snapshot.data ?? const <DemandeTransport>[];
          final visibles = _appliquerFiltre(demandes);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildSearchField(),
                ),
                _FiltreBar(
                  filtres: filtres,
                  selection: _filtre,
                  compteur: (cle) => cle == 'TOUTES'
                      ? demandes.length
                      : demandes
                            .where((d) => d.statut.toUpperCase() == cle)
                            .length,
                  onChanged: (cle) => setState(() => _filtre = cle),
                ),
                Expanded(
                  child: visibles.isEmpty
                      ? _EmptyState(
                          filtreActif: _filtre != 'TOUTES',
                          aDesDemandes: demandes.isNotEmpty,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: visibles.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _DemandCard(
                            demande: visibles[index],
                            onModifier: () => _modifier(visibles[index]),
                            onSupprimer: () => _supprimer(visibles[index]),
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

class _DemandCard extends StatelessWidget {
  final DemandeTransport demande;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _DemandCard({
    required this.demande,
    required this.onModifier,
    required this.onSupprimer,
  });

  Color _statusColor(String statut) => couleurStatut(statut);

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year}';
  }

  String _quantite(AppLocalizations l10n) {
    final quantite = demande.quantite;
    if (quantite == null) return l10n.historiqueClientQuantiteNonPrecisee;
    final valeur = quantite == quantite.roundToDouble()
        ? quantite.toStringAsFixed(0)
        : quantite.toStringAsFixed(2);
    return demande.unite.isEmpty ? valeur : '$valeur ${demande.unite}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final couleur = _statusColor(demande.statut);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                  demande.trajet,
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
                  demande.statut.toUpperCase(),
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.historiqueClientCreeeLabel(_formatDate(demande.dateCreation)),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetaChip(
                  icon: Icons.public_outlined,
                  label:
                      '${nomParPays(demande.paysDepart) ?? demande.paysDepart} → ${nomParPays(demande.paysArrivee) ?? demande.paysArrivee}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetaChip(
                  icon: Icons.inventory_2_outlined,
                  label: demande.produit,
                ),
              ),
              Expanded(
                child: _MetaChip(
                  icon: Icons.local_shipping_outlined,
                  label: l10n.historiqueClientCamionsValue(demande.nombreCamions),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetaChip(
                  icon: Icons.scale_outlined,
                  label: _quantite(l10n),
                ),
              ),
              Expanded(
                child: _MetaChip(
                  icon: Icons.event_outlined,
                  label: l10n.historiqueClientChargementLabel(_formatDate(demande.dateChargement)),
                ),
              ),
            ],
          ),
          if (demande.statut.toUpperCase() == 'OUVERTE') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onSupprimer,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(l10n.historiqueClientSupprimer),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
                TextButton.icon(
                  onPressed: onModifier,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l10n.historiqueClientModifier),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool filtreActif;
  final bool aDesDemandes;

  const _EmptyState({required this.filtreActif, required this.aDesDemandes});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final titre = filtreActif && aDesDemandes
        ? l10n.historiqueClientEmptyFiltered
        : l10n.historiqueClientEmptyNone;

    final detail = filtreActif && aDesDemandes
        ? l10n.historiqueClientChangeFilter
        : l10n.historiqueClientEmptyHint;

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
      children: [
        Icon(Icons.history_outlined, size: 56, color: Colors.grey.shade400),
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
