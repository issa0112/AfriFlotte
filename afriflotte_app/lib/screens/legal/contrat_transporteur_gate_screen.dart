import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/contrat.dart';
import '../../services/contrat_service.dart';
import '../../services/storage_service.dart';
import '../../screens/transporteur/transporteur_home.dart';
import '../auth/auth_screen.dart';
import 'contrat_screen.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Écran de blocage, imposé une fois par `naviguerApresConnexion` (cf.
/// `utils/auth_navigation.dart`) à tout transporteur dont le compte n'a pas
/// encore accepté la version courante du contrat de partenariat
/// (`user['contrat_transporteur_accepte'] != true`) — inscription antérieure
/// à l'introduction du contrat, ou contrat mis à jour depuis. Sans bouton
/// retour : la seule issue est d'accepter, ou de se déconnecter.
class ContratTransporteurGateScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;

  const ContratTransporteurGateScreen({
    super.key,
    required this.user,
    required this.token,
  });

  @override
  State<ContratTransporteurGateScreen> createState() =>
      _ContratTransporteurGateScreenState();
}

class _ContratTransporteurGateScreenState
    extends State<ContratTransporteurGateScreen> {
  Contrat? _contrat;
  String? _erreur;
  bool _coche = false;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);
    try {
      final contrat = await ContratService.getContratTransporteur();
      if (mounted) setState(() => _contrat = contrat);
    } catch (_) {
      if (mounted) {
        setState(
          () => _erreur = AppLocalizations.of(context).contratChargementErreur,
        );
      }
    }
  }

  Future<void> _telechargerPdf() async {
    await launchUrl(
      Uri.parse(ContratService.urlPdfContratTransporteur),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _accepter() async {
    setState(() => _envoi = true);
    try {
      await ContratService.accepterContratTransporteur(widget.token);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TransporteurHome(
            user: widget.user,
            token: widget.token,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _deconnecter() async {
    await StorageService.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.contratGateTitre),
          backgroundColor: _bleuNuit,
          foregroundColor: Colors.white,
          actions: [
            TextButton.icon(
              onPressed: _deconnecter,
              icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
              label: Text(
                l10n.contratGateDeconnexion,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Text(
                l10n.contratGateSousTitre,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(child: _corps(l10n)),
            _barreAction(l10n),
          ],
        ),
      ),
    );
  }

  Widget _corps(AppLocalizations l10n) {
    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 14),
              Text(_erreur!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _charger,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
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

    final contrat = _contrat;
    if (contrat == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ContratListe(contrat: contrat);
  }

  Widget _barreAction(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _contrat == null
                  ? null
                  : () => setState(() => _coche = !_coche),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Checkbox(
                      value: _coche,
                      onChanged: _contrat == null
                          ? null
                          : (v) => setState(() => _coche = v ?? false),
                      activeColor: _bleuAccent,
                    ),
                    Expanded(
                      child: Text(
                        l10n.contratGateCheckbox,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _contrat == null ? null : _telechargerPdf,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(l10n.contratTelechargerPdf),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_coche && !_envoi) ? _accepter : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bleuAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _envoi
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.contratGateAccepter,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
