import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/paiement.dart';
import '../../services/paiement_service.dart';

const _bleuNuit = Color(0xFF102C5C);

/// File d'attente admin : paiements MANUEL encaissés à valider (`ENCAISSE`)
/// et paiements libérés à verser au transporteur (`LIBERE`) —
/// `AdminPaiementsView` renvoie les deux par défaut, cette liste ne fait pas
/// de distinction visuelle forte au-delà du badge de statut puisque l'action
/// disponible (Valider/Marquer versé) déjà l'indique sans ambiguïté.
class AdminPaiementsScreen extends StatefulWidget {
  final String token;

  const AdminPaiementsScreen({super.key, required this.token});

  @override
  State<AdminPaiementsScreen> createState() => _AdminPaiementsScreenState();
}

class _AdminPaiementsScreenState extends State<AdminPaiementsScreen> {
  late Future<List<Paiement>> _future;

  @override
  void initState() {
    super.initState();
    _future = PaiementService.adminPaiements(widget.token);
  }

  Future<void> _rafraichir() async {
    final future = PaiementService.adminPaiements(widget.token);
    setState(() => _future = future);
    await future.catchError((_) => <Paiement>[]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.adminPaiementsTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Paiement>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final paiements = snapshot.data ?? const <Paiement>[];

          if (paiements.isEmpty) {
            return RefreshIndicator(
              onRefresh: _rafraichir,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 52,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.adminPaiementsEmpty,
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
              itemCount: paiements.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _CartePaiementAdmin(
                paiement: paiements[index],
                token: widget.token,
                onChange: _rafraichir,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartePaiementAdmin extends StatefulWidget {
  final Paiement paiement;
  final String token;
  final VoidCallback onChange;

  const _CartePaiementAdmin({
    required this.paiement,
    required this.token,
    required this.onChange,
  });

  @override
  State<_CartePaiementAdmin> createState() => _CartePaiementAdminState();
}

class _CartePaiementAdminState extends State<_CartePaiementAdmin> {
  bool _envoi = false;

  void _erreur(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _valider() async {
    setState(() => _envoi = true);
    try {
      await PaiementService.validerManuel(
        token: widget.token,
        paiementId: widget.paiement.id,
      );
      widget.onChange();
    } catch (e) {
      _erreur(e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _verser() async {
    final picker = ImagePicker();
    final preuve = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (!mounted) return;

    setState(() => _envoi = true);
    try {
      await PaiementService.verser(
        token: widget.token,
        paiementId: widget.paiement.id,
        reference: '',
        preuve: preuve,
      );
      widget.onChange();
    } catch (e) {
      _erreur(e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _rembourser() async {
    final l10n = AppLocalizations.of(context);
    final controleur = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminRembourserButton),
        content: TextField(
          controller: controleur,
          decoration: InputDecoration(
            labelText: l10n.adminMotifLabel,
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
      await PaiementService.rembourser(
        token: widget.token,
        paiementId: widget.paiement.id,
        motif: motif,
      );
      widget.onChange();
    } catch (e) {
      _erreur(e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paiement = widget.paiement;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
                  paiement.missionTrajet,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  paiement.statutLibelle,
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${paiement.clientNom} → ${paiement.transporteurNom} · ${paiement.montantTotal.toStringAsFixed(0)} ${paiement.devise}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
          if (paiement.mode == 'MANUEL')
            Text(
              'Mode manuel',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
            ),
          const SizedBox(height: 12),
          if (_envoi)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            )
          else
            Row(
              children: [
                if (paiement.statut == 'ENCAISSE')
                  Expanded(
                    child: FilledButton(
                      onPressed: _valider,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                      child: Text(l10n.adminValiderButton),
                    ),
                  ),
                if (paiement.statut == 'LIBERE')
                  Expanded(
                    child: FilledButton(
                      onPressed: _verser,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                      child: Text(l10n.adminVerserButton),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _rembourser,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                  child: Text(l10n.adminRembourserButton),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
