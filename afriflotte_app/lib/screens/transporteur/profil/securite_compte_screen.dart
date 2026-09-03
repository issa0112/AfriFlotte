import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/profil_service.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

enum _ForceMotDePasse { vide, faible, moyen, fort }

_ForceMotDePasse _evaluerForce(String motDePasse) {
  if (motDePasse.isEmpty) return _ForceMotDePasse.vide;
  if (motDePasse.length < 6) return _ForceMotDePasse.faible;

  var varietes = 0;
  if (RegExp(r'[a-z]').hasMatch(motDePasse)) varietes++;
  if (RegExp(r'[A-Z]').hasMatch(motDePasse)) varietes++;
  if (RegExp(r'[0-9]').hasMatch(motDePasse)) varietes++;
  if (RegExp(r'[^a-zA-Z0-9]').hasMatch(motDePasse)) varietes++;

  if (motDePasse.length >= 10 && varietes >= 3) return _ForceMotDePasse.fort;
  if (motDePasse.length >= 8 && varietes >= 2) return _ForceMotDePasse.moyen;
  return _ForceMotDePasse.faible;
}

/// Écran "Sécurité du compte" : changement de mot de passe. Le token JWT en
/// cours reste valide après coup (voir `ProfilService.changerMotDePasse`),
/// donc pas de déconnexion forcée — l'utilisateur reste sur l'app.
class SecuriteCompteScreen extends StatefulWidget {
  final String token;

  const SecuriteCompteScreen({super.key, required this.token});

  @override
  State<SecuriteCompteScreen> createState() => _SecuriteCompteScreenState();
}

class _SecuriteCompteScreenState extends State<SecuriteCompteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ancienController = TextEditingController();
  final _nouveauController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _ancienVisible = false;
  bool _nouveauVisible = false;
  bool _confirmationVisible = false;
  bool _loading = false;

  _ForceMotDePasse _force = _ForceMotDePasse.vide;

  @override
  void dispose() {
    _ancienController.dispose();
    _nouveauController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);

    try {
      await ProfilService.changerMotDePasse(
        token: widget.token,
        ancienMotDePasse: _ancienController.text,
        nouveauMotDePasse: _nouveauController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.securiteSuccess)),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(
    String label,
    bool visible,
    VoidCallback toggle,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: toggle,
      ),
      filled: true,
      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Color get _couleurForce {
    switch (_force) {
      case _ForceMotDePasse.faible:
        return Colors.redAccent;
      case _ForceMotDePasse.moyen:
        return Colors.orange;
      case _ForceMotDePasse.fort:
        return Colors.green;
      case _ForceMotDePasse.vide:
        return Colors.grey.shade300;
    }
  }

  String _libelleForce(AppLocalizations l10n) {
    switch (_force) {
      case _ForceMotDePasse.faible:
        return l10n.securiteStrengthWeak;
      case _ForceMotDePasse.moyen:
        return l10n.securiteStrengthMedium;
      case _ForceMotDePasse.fort:
        return l10n.securiteStrengthStrong;
      case _ForceMotDePasse.vide:
        return "";
    }
  }

  double get _proportionForce {
    switch (_force) {
      case _ForceMotDePasse.faible:
        return 1 / 3;
      case _ForceMotDePasse.moyen:
        return 2 / 3;
      case _ForceMotDePasse.fort:
        return 1;
      case _ForceMotDePasse.vide:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.securiteTitle),
        centerTitle: true,
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [_bleuNuit, _bleuAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.securiteIntro,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
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
                        const Icon(Icons.password_rounded, size: 18, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Text(
                          l10n.securiteChangePassword,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ancienController,
                      obscureText: !_ancienVisible,
                      decoration: _decoration(
                        l10n.securiteCurrentPassword,
                        _ancienVisible,
                        () => setState(() => _ancienVisible = !_ancienVisible),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? l10n.securiteCurrentPasswordRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nouveauController,
                      obscureText: !_nouveauVisible,
                      onChanged: (value) => setState(() => _force = _evaluerForce(value)),
                      decoration: _decoration(
                        l10n.securiteNewPassword,
                        _nouveauVisible,
                        () => setState(() => _nouveauVisible = !_nouveauVisible),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return l10n.securiteNewPasswordRequired;
                        if (value.length < 6) return l10n.securitePasswordMinLength;
                        return null;
                      },
                    ),
                    if (_force != _ForceMotDePasse.vide) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: _proportionForce,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                color: _couleurForce,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _libelleForce(l10n),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _couleurForce,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmationController,
                      obscureText: !_confirmationVisible,
                      decoration: _decoration(
                        l10n.securiteConfirmPassword,
                        _confirmationVisible,
                        () => setState(() => _confirmationVisible = !_confirmationVisible),
                      ),
                      validator: (value) => (value != _nouveauController.text)
                          ? l10n.securitePasswordMismatch
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _valider,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bleuNuit,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : Text(
                          l10n.securiteUpdateButton,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
