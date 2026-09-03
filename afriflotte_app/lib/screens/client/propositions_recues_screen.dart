import 'package:flutter/material.dart';

import '../../constants/statut_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/proposition.dart';
import '../../services/proposition_service.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Propositions envoyées par les transporteurs pour les demandes de
/// l'entreprise : c'est ici que la boucle "notification → décision" se
/// termine, en Accepter (crée la mission, cf. `accepter_proposition_service`
/// côté Django, qui refuse aussi les autres propositions concurrentes) ou
/// Refuser (statut REFUSEE, transporteur notifié, sans toucher aux autres).
class PropositionsRecuesScreen extends StatefulWidget {
  final String token;
  final bool embedded;

  // Proposition à mettre en évidence quand l'écran est ouvert depuis une
  // notification — évite de retomber sur le filtre "En attente" par défaut
  // si la proposition visée a déjà été traitée, et signale si elle a
  // entre-temps disparu (cf. `AppNotification.propositionId`).
  final int? highlightId;

  const PropositionsRecuesScreen({
    super.key,
    required this.token,
    this.embedded = false,
    this.highlightId,
  });

  @override
  State<PropositionsRecuesScreen> createState() =>
      _PropositionsRecuesScreenState();
}

class _PropositionsRecuesScreenState extends State<PropositionsRecuesScreen> {
  late Future<List<Proposition>> _futurePropositions;
  late String _filtre;

  // Verrouille une carte pendant l'appel réseau pour éviter un double-tap
  // sur Accepter/Refuser (l'un créerait une mission, l'autre échouerait sur
  // un statut déjà changé).
  int? _idEnCours;

  bool _absenceSignalee = false;

  @override
  void initState() {
    super.initState();
    _filtre = widget.highlightId != null ? 'TOUTES' : 'EN_ATTENTE';
    _futurePropositions = PropositionService.getPropositions(widget.token);
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
    if (_filtre == 'TOUTES') return propositions;
    return propositions.where((p) => p.statut == _filtre).toList();
  }

  Future<void> _accepter(Proposition proposition) async {
    final l10n = AppLocalizations.of(context);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.propositionsRecuesConfirmerAccepterTitle),
        content: Text(l10n.propositionsRecuesConfirmerAccepterMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.propositionsRecuesAccepterButton),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _idEnCours = proposition.id);
    try {
      await PropositionService.accepterProposition(widget.token, proposition.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.propositionsRecuesAccepteeSuccess)),
      );
      await _rafraichir();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _idEnCours = null);
    }
  }

  Future<void> _refuser(Proposition proposition) async {
    final l10n = AppLocalizations.of(context);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.propositionsRecuesConfirmerRefuserTitle),
        content: Text(l10n.propositionsRecuesConfirmerRefuserMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.propositionsRecuesRefuserButton,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _idEnCours = proposition.id);
    try {
      await PropositionService.refuserProposition(widget.token, proposition.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.propositionsRecuesRefuseeSuccess)),
      );
      await _rafraichir();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _idEnCours = null);
    }
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
        title: Text(l10n.propositionsRecuesTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !widget.embedded,
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
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _PropositionCard(
                            proposition: visibles[index],
                            enCours: _idEnCours == visibles[index].id,
                            enEvidence: widget.highlightId == visibles[index].id,
                            onAccepter: () => _accepter(visibles[index]),
                            onRefuser: () => _refuser(visibles[index]),
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
  final bool enCours;
  final bool enEvidence;
  final VoidCallback onAccepter;
  final VoidCallback onRefuser;

  const _PropositionCard({
    required this.proposition,
    required this.enCours,
    this.enEvidence = false,
    required this.onAccepter,
    required this.onRefuser,
  });

  Color get _statutColor => couleurStatut(proposition.statut);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final devise = proposition.devise ?? '';
    final initiale = proposition.transporteurNom.trim().isNotEmpty
        ? proposition.transporteurNom.trim()[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: enEvidence ? Border.all(color: _bleuAccent, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: (enEvidence ? _bleuAccent : Colors.black)
                .withValues(alpha: enEvidence ? 0.16 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bandeau : identité du transporteur + trajet, sur le dégradé
          // signature de l'app (mêmes teintes que les en-têtes d'écran) —
          // distingue immédiatement "qui propose quoi" avant le détail.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bleuNuit, _bleuAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    initiale,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        proposition.transporteurNom,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        proposition.trajet,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    proposition.statutLibelle,
                    style: TextStyle(
                      color: _statutColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prix mis en avant dans un encart dédié plutôt que noyé dans
                // une ligne parmi d'autres — c'est l'info sur laquelle porte
                // la décision Accepter/Refuser.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _bleuAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_rounded, color: _bleuAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.propositionsRecuesPrixLabel,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      Text(
                        '${proposition.prix.toStringAsFixed(0)} $devise'.trim(),
                        style: const TextStyle(
                          color: _bleuNuit,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
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
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade300, width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.propositionsRecuesMessageLabel,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          proposition.message!,
                          style: const TextStyle(fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
                if (proposition.statut == 'EN_ATTENTE') ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: enCours ? null : onRefuser,
                          icon: const Icon(Icons.close_rounded, size: 17),
                          label: Text(l10n.propositionsRecuesRefuserButton),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_bleuNuit, _bleuAccent],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: enCours ? null : onAccepter,
                            icon: enCours
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(l10n.propositionsRecuesAccepterButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

/// Pastille compacte icône + texte — même DNA visuelle que `_InfoChip` de
/// `demandes_disponibles.dart` (côté transporteur), pour garder les deux
/// bouts du flux propositions cohérents visuellement.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
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

  const _EmptyState({required this.filtreActif, required this.aDesPropositions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final titre = filtreActif && aDesPropositions
        ? l10n.propositionsRecuesEmptyFiltered
        : l10n.propositionsRecuesEmptyNone;

    final detail = filtreActif && aDesPropositions
        ? l10n.propositionsRecuesChangeFilter
        : l10n.propositionsRecuesEmptyHint;

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
      children: [
        Icon(
          Icons.local_offer_outlined,
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
