import 'package:flutter/material.dart';

import '../../../constants/pays_cedeao.dart';
import '../../../constants/statut_style.dart';
import '../../../constants/type_camion.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/demande_transport.dart';
import '../../../services/demande_transport_service.dart';
import 'creer_proposition_screen.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Demandes de transport ouvertes sur le marché : le transporteur peut y
/// répondre par une proposition (`CreerPropositionScreen`). Ne pas confondre
/// avec les missions du transporteur (`MesMissionsScreen`) : une demande
/// devient une mission seulement après acceptation d'une proposition.
class DemandesDisponibles extends StatefulWidget {
  final String token;

  const DemandesDisponibles({super.key, required this.token});

  @override
  State<DemandesDisponibles> createState() => _DemandesDisponiblesState();
}

class _DemandesDisponiblesState extends State<DemandesDisponibles> {
  List<DemandeTransport> _demandes = [];
  List<DemandeTransport> _filtered = [];

  bool _loading = true;
  String? _error;
  String _statusFilter = "TOUS";

  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = const [
    "TOUS",
    "OUVERTE",
    "EN_COURS",
    "TERMINEE",
    "ANNULEE",
  ];

  @override
  void initState() {
    super.initState();
    _chargerDemandes();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargerDemandes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await DemandeTransportService.getDemandes(widget.token);

      if (!mounted) return;

      setState(() {
        _demandes = data;
        _loading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).demandesLoadError;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filtered = _demandes.where((d) {
        final statusOk = _statusFilter == "TOUS" || d.statut == _statusFilter;

        final textOk =
            query.isEmpty ||
            d.depart.toLowerCase().contains(query) ||
            d.destination.toLowerCase().contains(query) ||
            d.produit.toLowerCase().contains(query);

        return statusOk && textOk;
      }).toList();
    });
  }

  Color _statusColor(String status) => couleurStatut(status);

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case "TOUS":
        return l10n.demandesFilterAll;
      case "OUVERTE":
        return l10n.demandesStatusOuverte;
      case "EN_COURS":
        return l10n.demandesStatusEnCours;
      case "TERMINEE":
        return l10n.demandesStatusTerminee;
      case "ANNULEE":
        return l10n.demandesStatusAnnulee;
      default:
        return status;
    }
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final total = _filtered.length;
    final ouvertes = _filtered.where((d) => d.statut == "OUVERTE").length;
    final enCours = _filtered.where((d) => d.statut == "EN_COURS").length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_bleuNuit, _bleuAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(label: l10n.demandesTotal, value: "$total"),
          ),
          Expanded(
            child: _StatItem(label: l10n.demandesOuvertes, value: "$ouvertes"),
          ),
          Expanded(
            child: _StatItem(label: l10n.demandesEnCours, value: "$enCours"),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = _statusFilter == filter;

          return ChoiceChip(
            label: Text(_statusLabel(l10n, filter)),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _statusFilter = filter;
              });
              _applyFilters();
            },
            selectedColor: _bleuNuit,
            labelStyle: TextStyle(
              color: selected ? Colors.white : _bleuNuit,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(
              color: selected ? _bleuNuit : Colors.grey.shade300,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildSearch(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: l10n.demandesSearchHint,
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

  Future<void> _proposer(DemandeTransport demande) async {
    final envoye = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreerPropositionScreen(token: widget.token, demande: demande),
      ),
    );

    if (envoye == true) _chargerDemandes();
  }

  Widget _buildDemandeCard(AppLocalizations l10n, DemandeTransport demande) {
    final statusColor = _statusColor(demande.statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${demande.depart} → ${demande.destination}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(l10n, demande.statut),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.public_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${nomParPays(demande.paysDepart) ?? demande.paysDepart} → ${nomParPays(demande.paysArrivee) ?? demande.paysArrivee}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.local_shipping_outlined,
                              label: libelleTypeCamion(
                                l10n,
                                demande.typeCamion,
                              ),
                              accent: _bleuAccent,
                            ),
                            _InfoChip(
                              icon: Icons.inventory_2_outlined,
                              label: demande.produit,
                            ),
                            _InfoChip(
                              icon: Icons.format_list_numbered_rounded,
                              label: l10n.demandesCamionCount(
                                demande.nombreCamions,
                              ),
                            ),
                            if (demande.prixPropose != null)
                              _InfoChip(
                                icon: Icons.payments_outlined,
                                label: formatMontant(
                                  demande.prixPropose,
                                  demande.devise,
                                ),
                                accent: const Color(0xFF34D399),
                              ),
                          ],
                        ),
                        if (demande.statut == "OUVERTE") ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _proposer(demande),
                              icon: const Icon(Icons.send, size: 16),
                              label: Text(l10n.demandesProposeButton),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _bleuNuit,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 42, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _chargerDemandes,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          l10n.demandesNoneFound,
          style: const TextStyle(fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _chargerDemandes,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filtered.length,
        itemBuilder: (context, index) =>
            _buildDemandeCard(l10n, _filtered[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.demandesTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            onPressed: _chargerDemandes,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 12),
            _buildSearch(l10n),
            const SizedBox(height: 10),
            _buildFilters(l10n),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _InfoChip({required this.icon, required this.label, this.accent});

  @override
  Widget build(BuildContext context) {
    final couleur = accent ?? Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent?.withValues(alpha: 0.10) ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: couleur),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accent != null ? couleur : Colors.grey.shade800,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
