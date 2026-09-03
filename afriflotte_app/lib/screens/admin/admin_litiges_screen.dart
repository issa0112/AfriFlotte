import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/litige.dart';
import '../../services/paiement_service.dart';

const _bleuNuit = Color(0xFF102C5C);

/// File d'attente admin des litiges ouverts (`AdminLitigesView`) — résoudre
/// débloque la libération/le remboursement en attente côté paiement
/// (`resoudre_litige_service`).
class AdminLitigesScreen extends StatefulWidget {
  final String token;

  const AdminLitigesScreen({super.key, required this.token});

  @override
  State<AdminLitigesScreen> createState() => _AdminLitigesScreenState();
}

class _AdminLitigesScreenState extends State<AdminLitigesScreen> {
  late Future<List<Litige>> _future;

  @override
  void initState() {
    super.initState();
    _future = PaiementService.adminLitiges(widget.token);
  }

  Future<void> _rafraichir() async {
    final future = PaiementService.adminLitiges(widget.token);
    setState(() => _future = future);
    await future.catchError((_) => <Litige>[]);
  }

  Future<void> _resoudre(Litige litige) async {
    final l10n = AppLocalizations.of(context);
    final commentaireController = TextEditingController();

    final resolution = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminResoudreButton),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(litige.motif),
            const SizedBox(height: 12),
            TextField(
              controller: commentaireController,
              decoration: InputDecoration(
                labelText: l10n.adminCommentaireLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('RESOLU_CLIENT'),
            child: Text(l10n.adminResolutionClient, textAlign: TextAlign.right),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop('RESOLU_TRANSPORTEUR'),
            child: Text(l10n.adminResolutionTransporteur),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('REJETE'),
            child: Text(l10n.adminResolutionRejete),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );

    if (resolution == null || !mounted) return;

    try {
      await PaiementService.resoudreLitige(
        token: widget.token,
        litigeId: litige.id,
        resolution: resolution,
        commentaire: commentaireController.text.trim(),
      );
      _rafraichir();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.adminLitigesTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Litige>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final litiges = snapshot.data ?? const <Litige>[];

          if (litiges.isEmpty) {
            return RefreshIndicator(
              onRefresh: _rafraichir,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
                children: [
                  Icon(
                    Icons.gavel_rounded,
                    size: 52,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.adminLitigesEmpty,
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
              itemCount: litiges.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final litige = litiges[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      Text(
                        litige.motif,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.adminMotifLabel} · ${litige.ouvertParNom ?? '—'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _resoudre(litige),
                          style: FilledButton.styleFrom(
                            backgroundColor: _bleuNuit,
                          ),
                          child: Text(l10n.adminResoudreButton),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
