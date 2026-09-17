import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/mot_de_passe_oublie_service.dart';
import 'auth_theme.dart';

// Même contrôle que le champ de connexion (auth_screen.dart) : pas de
// sélecteur de pays ici non plus, donc juste un contrôle structurel.
final RegExp _telephoneLoginPlausible = RegExp(r'^\d{6,10}$');

/// Flux "mot de passe oublié" en 3 étapes (téléphone → code + nouveau mot de
/// passe → succès), sur son propre écran poussé depuis `AuthScreen`.
/// Réutilise strictement les briques de `auth_theme.dart` (mêmes couleurs,
/// mêmes composants) plutôt que d'introduire un style à part.
class MotDePasseOublieScreen extends StatefulWidget {
  const MotDePasseOublieScreen({super.key});

  @override
  State<MotDePasseOublieScreen> createState() => _MotDePasseOublieScreenState();
}

enum _Etape { telephone, codeEtMotDePasse, succes }

class _MotDePasseOublieScreenState extends State<MotDePasseOublieScreen> {
  _Etape _etape = _Etape.telephone;

  final _telephoneFormKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();

  final _codeFormKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nouveauMotDePasseController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _nouveauVisible = false;
  bool _confirmationVisible = false;

  bool _loading = false;
  bool _renvoiEnCours = false;

  @override
  void dispose() {
    _telephoneController.dispose();
    _codeController.dispose();
    _nouveauMotDePasseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  String _erreur(Object e) => '$e'.replaceFirst('Exception: ', '');

  Future<void> _demanderCode() async {
    if (!(_telephoneFormKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      await MotDePasseOublieService.demanderCode(
        _telephoneController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _etape = _Etape.codeEtMotDePasse);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_erreur(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _renvoyerCode() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _renvoiEnCours = true);

    try {
      await MotDePasseOublieService.demanderCode(
        _telephoneController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.forgotNewCodeGenerated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_erreur(e))));
    } finally {
      if (mounted) setState(() => _renvoiEnCours = false);
    }
  }

  Future<void> _reinitialiser() async {
    if (!(_codeFormKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      await MotDePasseOublieService.confirmerReinitialisation(
        telephone: _telephoneController.text.trim(),
        code: _codeController.text.trim(),
        nouveauMotDePasse: _nouveauMotDePasseController.text,
      );

      if (!mounted) return;
      setState(() => _etape = _Etape.succes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_erreur(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authInk,
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AuthCard(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: switch (_etape) {
                      _Etape.telephone => _etapeTelephone(),
                      _Etape.codeEtMotDePasse => _etapeCodeEtMotDePasse(),
                      _Etape.succes => _etapeSucces(),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _boutonRetour() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded, color: authTextDark),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 20,
      ),
    );
  }

  Widget _etapeTelephone() {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _telephoneFormKey,
      child: Column(
        key: const ValueKey('etape_telephone'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _boutonRetour(),
          const SizedBox(height: 10),
          Text(l10n.forgotStep1Of2, style: authEyebrow()),
          const SizedBox(height: 8),
          Text(l10n.forgotTitle, style: authHeading(size: 25)),
          const SizedBox(height: 6),
          Text(l10n.forgotSubtitle, style: authBody()),
          const SizedBox(height: 26),
          TextFormField(
            controller: _telephoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            style: authBody(color: authTextDark, weight: FontWeight.w500),
            decoration: authInputDecoration(l10n.authPhoneLabel, Icons.phone_outlined),
            onFieldSubmitted: (_) => _demanderCode(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return l10n.authPhoneRequired;
              return _telephoneLoginPlausible.hasMatch(value.trim())
                  ? null
                  : l10n.authPhoneInvalid;
            },
          ),
          const SizedBox(height: 26),
          AuthPrimaryButton(
            label: l10n.forgotSendCodeButton,
            loading: _loading,
            onPressed: _demanderCode,
          ),
        ],
      ),
    );
  }

  Widget _etapeCodeEtMotDePasse() {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _codeFormKey,
      child: Column(
        key: const ValueKey('etape_code'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => setState(() => _etape = _Etape.telephone),
              icon: const Icon(Icons.arrow_back_rounded, color: authTextDark),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(l10n.forgotStep2Of2, style: authEyebrow()),
          const SizedBox(height: 8),
          Text(l10n.forgotVerificationTitle, style: authHeading(size: 25)),
          const SizedBox(height: 6),
          Text(l10n.forgotVerificationSubtitle, style: authBody()),
          const SizedBox(height: 20),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              color: authTextDark,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 10,
            ),
            decoration: authInputDecoration(l10n.forgotCodeLabel, Icons.pin_outlined).copyWith(
              counterText: '',
            ),
            validator: (value) => (value == null || value.trim().length != 6)
                ? l10n.forgotCodeInvalid
                : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _renvoiEnCours ? null : _renvoyerCode,
              style: TextButton.styleFrom(foregroundColor: authMintDim, padding: EdgeInsets.zero),
              child: Text(
                _renvoiEnCours ? l10n.forgotResendCodeInProgress : l10n.forgotResendCode,
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nouveauMotDePasseController,
            obscureText: !_nouveauVisible,
            style: authBody(color: authTextDark, weight: FontWeight.w500),
            decoration: authInputDecoration(
              l10n.forgotNewPasswordLabel,
              Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _nouveauVisible = !_nouveauVisible),
                icon: Icon(
                  _nouveauVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: authMintDim,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.forgotNewPasswordRequired;
              if (value.length < 6) return l10n.authPasswordMinLength;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmationController,
            obscureText: !_confirmationVisible,
            textInputAction: TextInputAction.done,
            style: authBody(color: authTextDark, weight: FontWeight.w500),
            onFieldSubmitted: (_) => _reinitialiser(),
            decoration: authInputDecoration(
              l10n.authConfirmPasswordLabel,
              Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _confirmationVisible = !_confirmationVisible),
                icon: Icon(
                  _confirmationVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: authMintDim,
                ),
              ),
            ),
            validator: (value) => value != _nouveauMotDePasseController.text
                ? l10n.authPasswordMismatch
                : null,
          ),
          const SizedBox(height: 26),
          AuthPrimaryButton(
            label: l10n.forgotResetButton,
            loading: _loading,
            onPressed: _reinitialiser,
          ),
        ],
      ),
    );
  }

  Widget _etapeSucces() {
    final l10n = AppLocalizations.of(context);

    return Column(
      key: const ValueKey('etape_succes'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [authPanelDark, authPanelTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: authMintDim.withValues(alpha: 0.4),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 22),
        Text(l10n.forgotSuccessTitle, style: authHeading(size: 22), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          l10n.forgotSuccessSubtitle,
          style: authBody(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 26),
        AuthPrimaryButton(
          label: l10n.forgotBackToLogin,
          loading: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
