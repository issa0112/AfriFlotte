import 'package:flutter/material.dart';

import '../../constants/pays_cedeao.dart';
import '../../constants/statut_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/demande_transport.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_entity_list.dart';

const _bleuFonce = Color(0xFF071A3A);
const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Vue admin plateforme de toutes les demandes de transport, tous clients
/// confondus (`GET /admin/demandes/`) — ouverte depuis la carte
/// "Demandes ouvertes" du tableau de bord admin.
class AdminDemandesScreen extends StatefulWidget {
  final String token;
  final String? initialFilter;

  const AdminDemandesScreen({
    super.key,
    required this.token,
    this.initialFilter,
  });

  @override
  State<AdminDemandesScreen> createState() => _AdminDemandesScreenState();
}

class _AdminDemandesScreenState extends State<AdminDemandesScreen> {
  late Future<List<DemandeTransport>> _future;
  late String _filtre;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _filtre = widget.initialFilter ?? 'TOUTES';
    _future = AdminService.getDemandes(widget.token);
  }

  Future<void> _rafraichir() async {
    final future = AdminService.getDemandes(widget.token);
    setState(() => _future = future);
    await future.catchError((_) => <DemandeTransport>[]);
  }

  List<DemandeTransport> _filtrer(List<DemandeTransport> liste) {
    var resultat = _filtre == 'TOUTES'
        ? liste
        : liste.where((d) => d.statut.toUpperCase() == _filtre).toList();
    final terme = _recherche.trim().toLowerCase();
    if (terme.isNotEmpty) {
      resultat = resultat
          .where(
            (d) =>
                d.trajet.toLowerCase().contains(terme) ||
                (d.clientNom ?? '').toLowerCase().contains(terme),
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
      'OUVERTE': l10n.adminDemandesFilterOuverte,
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
                          l10n.adminDemandesTitle,
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
            child: FutureBuilder<List<DemandeTransport>>(
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

                final demandes = _filtrer(snapshot.data ?? const []);

                if (demandes.isEmpty) {
                  return _EtatVide(
                    message: l10n.adminDemandesEmpty,
                    rechercheActive: _recherche.isNotEmpty,
                    l10n: l10n,
                  );
                }

                return ResponsiveEntityList<DemandeTransport>(
                  items: demandes,
                  onRefresh: _rafraichir,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  mobileCardBuilder: (context, demande) =>
                      _CarteDemande(demande: demande),
                  columns: [
                    TableColumn<DemandeTransport>(
                      label: l10n.tableColonneTrajet,
                      sortBy: (a, b) => a.trajet.compareTo(b.trajet),
                      cell: (d) => DataCell(Text(d.trajet)),
                    ),
                    TableColumn<DemandeTransport>(
                      label: l10n.tableColonneClient,
                      sortBy: (a, b) =>
                          (a.clientNom ?? '').compareTo(b.clientNom ?? ''),
                      cell: (d) => DataCell(Text(d.clientNom ?? '—')),
                    ),
                    TableColumn<DemandeTransport>(
                      label: l10n.tableColonneProduit,
                      cell: (d) => DataCell(Text(d.produit)),
                    ),
                    TableColumn<DemandeTransport>(
                      label: l10n.tableColonneStatut,
                      cell: (d) => DataCell(_badgeStatutDemande(l10n, d)),
                    ),
                    TableColumn<DemandeTransport>(
                      label: l10n.tableColonneMontant,
                      numeric: true,
                      sortBy: (a, b) =>
                          (a.prixPropose ?? 0).compareTo(b.prixPropose ?? 0),
                      cell: (d) => DataCell(
                        Text(formatMontant(d.prixPropose, d.devise)),
                      ),
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
                  : Icons.campaign_outlined,
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

String _libelleStatutDemande(AppLocalizations l10n, DemandeTransport demande) {
  switch (demande.statut.toUpperCase()) {
    case 'OUVERTE':
      return l10n.adminDemandesFilterOuverte;
    case 'EN_COURS':
      return l10n.missionsClientFilterEnCours;
    case 'TERMINEE':
      return l10n.missionsClientFilterTerminee;
    case 'ANNULEE':
      return l10n.missionsClientFilterAnnulee;
    default:
      return demande.statut;
  }
}

Widget _badgeStatutDemande(AppLocalizations l10n, DemandeTransport demande) {
  final couleur = couleurStatut(demande.statut);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: couleur.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      _libelleStatutDemande(l10n, demande),
      style: TextStyle(
        color: couleur,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    ),
  );
}

class _CarteDemande extends StatelessWidget {
  final DemandeTransport demande;

  const _CarteDemande({required this.demande});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final couleur = couleurStatut(demande.statut);

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
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _libelleStatutDemande(l10n, demande),
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
                  demande.clientNom ?? '—',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  demande.produit,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
              ),
              Text(
                formatMontant(demande.prixPropose, demande.devise),
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
