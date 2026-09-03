import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/paiement_service.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

const _tentativesMax = 15;
const _intervalleSondage = Duration(seconds: 2);

enum _Etape { chargement, verification, succes, echec, annule }

/// Affiche la page de paiement PayDunya (hébergée par le prestataire, pas par
/// AfriFlotte) dans une WebView intégrée à l'app — reste visuellement dans
/// AfriFlotte, contrairement à un `url_launcher` qui ouvrirait le navigateur
/// système. Voir `core/gateway_paiement.py:PayDunyaGatewayAdapter` pour la
/// contrepartie serveur.
///
/// PayDunya redirige vers `return_url`/`cancel_url` (construites côté
/// serveur, cf. `PAIEMENT_RETOUR_BASE_URL`) une fois le paiement terminé :
/// cette navigation est interceptée ici plutôt que laissée s'afficher, pour
/// fermer la WebView immédiatement. La confirmation réelle arrive de façon
/// asynchrone par webhook PayDunya (`core/views.py:paiement_webhook`) — un
/// court sondage de `GET /missions/<id>/paiement/` après la fermeture de la
/// WebView laisse le temps à ce webhook d'arriver.
class PaiementWebViewScreen extends StatefulWidget {
  final String token;
  final int missionId;
  final String checkoutUrl;

  const PaiementWebViewScreen({
    super.key,
    required this.token,
    required this.missionId,
    required this.checkoutUrl,
  });

  @override
  State<PaiementWebViewScreen> createState() => _PaiementWebViewScreenState();
}

class _PaiementWebViewScreenState extends State<PaiementWebViewScreen> {
  late final WebViewController _controller;
  _Etape _etape = _Etape.chargement;
  int _tentative = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _surNavigation),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  FutureOr<NavigationDecision> _surNavigation(NavigationRequest requete) {
    final url = requete.url;

    if (url.contains('/paiements/retour/')) {
      _demarrerVerification();
      return NavigationDecision.prevent;
    }

    if (url.contains('/paiements/annule/')) {
      setState(() => _etape = _Etape.annule);
      return NavigationDecision.prevent;
    }

    // Certaines étapes mobile money (Orange Money, Wave...) renvoient vers un
    // schéma non-http (deep link app, USSD...) plutôt que de rester sur la
    // page web — on laisse l'OS gérer ça plutôt que la WebView.
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  void _demarrerVerification() {
    setState(() {
      _etape = _Etape.verification;
      _tentative = 0;
    });
    _sonder();
  }

  Future<void> _sonder() async {
    if (!mounted || _etape != _Etape.verification) return;

    try {
      final paiement = await PaiementService.getPaiementMission(
        token: widget.token,
        missionId: widget.missionId,
      );

      if (!mounted) return;

      if (paiement?.statut == 'SECURISE') {
        setState(() => _etape = _Etape.succes);
        return;
      }
      if (paiement?.statut == 'ECHEC') {
        setState(() => _etape = _Etape.echec);
        return;
      }
    } catch (_) {
      // Sondage silencieux : une erreur réseau ponctuelle ne doit pas
      // interrompre le suivi, la prochaine tentative réessaiera.
    }

    _tentative++;
    if (_tentative >= _tentativesMax) {
      if (mounted) setState(() => _etape = _Etape.echec);
      return;
    }

    Future.delayed(_intervalleSondage, _sonder);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: _bleuNuit,
      appBar: AppBar(
        title: Text(l10n.paiementTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: switch (_etape) {
        _Etape.chargement => WebViewWidget(controller: _controller),
        _Etape.verification => _messageCentre(
            child: const CircularProgressIndicator(color: Colors.white70),
            texte: l10n.paiementEnAttenteConfirmation,
          ),
        _Etape.succes => _messageCentre(
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 64),
            texte: l10n.paiementSucces,
            bouton: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: _bleuAccent, foregroundColor: Colors.white),
              child: const Text('OK'),
            ),
          ),
        _Etape.echec => _messageCentre(
            child: const Icon(Icons.error_rounded, color: Color(0xFFEF4444), size: 64),
            texte: _tentative >= _tentativesMax
                ? l10n.paiementVerificationDelaiDepasse
                : l10n.paiementEchecTitre,
            bouton: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(l10n.paiementReessayer),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
            ),
          ),
        _Etape.annule => _messageCentre(
            child: const Icon(Icons.cancel_outlined, color: Colors.white70, size: 64),
            texte: l10n.paiementAnnuleParClient,
            bouton: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(l10n.paiementReessayer),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
            ),
          ),
      },
    );
  }

  Widget _messageCentre({required Widget child, required String texte, Widget? bouton}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 18),
            Text(
              texte,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            if (bouton != null) ...[const SizedBox(height: 24), bouton],
          ],
        ),
      ),
    );
  }
}
