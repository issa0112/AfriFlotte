import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/mission.dart';
import '../../services/paiement_service.dart';
import 'paiement_carte_screen.dart';
import 'paiement_webview_screen.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Choix du mode de paiement d'une mission (carte ou main à main), ouvert
/// depuis la carte de mission côté client. Crée le `Paiement` côté serveur
/// via `PaiementService.initierPaiement` puis :
/// - CARTE avec `checkout_url` (PayDunya, page hébergée) : ouvre
///   [PaiementWebViewScreen] — la page reste intégrée à l'app (WebView), pas
///   un navigateur externe.
/// - CARTE sans `checkout_url` (simulateur, formulaire natif) : ouvre
///   [PaiementCarteScreen].
/// - MANUEL : rien de plus à faire ici, un agent AfriFlotte encaissera plus
///   tard — l'écran se referme en confirmant que la demande est enregistrée.
class ChoisirModePaiementScreen extends StatefulWidget {
  final String token;
  final Mission mission;

  const ChoisirModePaiementScreen({
    super.key,
    required this.token,
    required this.mission,
  });

  @override
  State<ChoisirModePaiementScreen> createState() =>
      _ChoisirModePaiementScreenState();
}

class _ChoisirModePaiementScreenState extends State<ChoisirModePaiementScreen> {
  String _mode = 'CARTE';
  bool _envoi = false;

  void _erreur(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmer() async {
    setState(() => _envoi = true);
    try {
      final (paiement, checkoutUrl) = await PaiementService.initierPaiement(
        token: widget.token,
        missionId: widget.mission.id,
        mode: _mode,
      );

      if (!mounted) return;

      if (_mode == 'CARTE' && checkoutUrl != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaiementWebViewScreen(
              token: widget.token,
              missionId: widget.mission.id,
              checkoutUrl: checkoutUrl,
            ),
          ),
        );
        return;
      }

      if (_mode == 'CARTE') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaiementCarteScreen(
              token: widget.token,
              paiementId: paiement.id,
              montant: widget.mission.prixFinal ?? 0,
              devise: widget.mission.devise ?? '',
              trajet: widget.mission.trajet,
            ),
          ),
        );
        return;
      }

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).agentEncaissementConfirme),
        ),
      );
    } catch (e) {
      _erreur('$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mission = widget.mission;
    final montant = mission.prixFinal ?? 0;
    final commission = montant * 0.05;
    final net = montant - commission;
    final devise = mission.devise ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.paiementTitle),
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
                Text(
                  mission.trajet,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                _LigneMontant(
                  label: l10n.paiementMontantTotal,
                  valeur: montant,
                  devise: devise,
                  gras: true,
                ),
                const SizedBox(height: 8),
                _LigneMontant(
                  label: l10n.paiementCommission('5'),
                  valeur: commission,
                  devise: devise,
                  couleur: Colors.grey.shade600,
                ),
                const Divider(height: 24),
                _LigneMontant(
                  label: l10n.paiementNetTransporteur,
                  valeur: net,
                  devise: devise,
                  couleur: const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l10n.paiementChooseModeTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _CarteMode(
            icone: Icons.credit_card_rounded,
            titre: l10n.paiementModeCarte,
            sousTitre: l10n.paiementModeCarteDesc,
            selectionne: _mode == 'CARTE',
            onTap: () => setState(() => _mode = 'CARTE'),
          ),
          const SizedBox(height: 10),
          _CarteMode(
            icone: Icons.payments_rounded,
            titre: l10n.paiementModeManuel,
            sousTitre: l10n.paiementModeManuelDesc,
            selectionne: _mode == 'MANUEL',
            onTap: () => setState(() => _mode = 'MANUEL'),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _envoi ? null : _confirmer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _bleuAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _envoi
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.paiementValider,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LigneMontant extends StatelessWidget {
  final String label;
  final double valeur;
  final String devise;
  final bool gras;
  final Color? couleur;

  const _LigneMontant({
    required this.label,
    required this.valeur,
    required this.devise,
    this.gras = false,
    this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: gras ? FontWeight.w800 : FontWeight.w600,
      fontSize: gras ? 17 : 14,
      color: couleur ?? Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: gras ? 14 : 13,
          ),
        ),
        Text('${valeur.toStringAsFixed(0)} $devise', style: style),
      ],
    );
  }
}

class _CarteMode extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;
  final bool selectionne;
  final VoidCallback onTap;

  const _CarteMode({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.selectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selectionne ? _bleuAccent : Colors.grey.shade300,
              width: selectionne ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icone,
                color: selectionne ? _bleuAccent : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sousTitre,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selectionne
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selectionne ? _bleuAccent : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
