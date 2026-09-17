import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../constants/pays_cedeao.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../utils/auth_navigation.dart';
import '../../utils/telephone.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/pays_dropdown.dart';
import '../chauffeur/chauffeur_dashboard_screen.dart';

import 'auth_theme.dart';
import 'mot_de_passe_oublie_screen.dart';

final RegExp _emailValide = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// Pas de sélecteur de pays à la connexion (le numéro y est saisi sans
// indicatif) : contrôle purement structurel, la longueur exacte dépend du
// pays qu'on ne connaît pas encore à ce stade.
final RegExp _telephoneLoginPlausible = RegExp(r'^\d{6,10}$');

/// Écran d'authentification unique : connexion et inscription cohabitent
/// dans le même panneau, qui glisse de l'une à l'autre (mise en page large,
/// bureau/web) ou bascule instantanément (mobile étroit), comme le fait le
/// design d'origine (media query à 760px).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  static const _breakpoint = 760.0;

  bool _isSignup = false;

  late final AnimationController _slide;
  late final Animation<double> _t;

  // --- Connexion ---
  final _loginFormKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loginPasswordVisible = false;
  bool _loginLoading = false;

  // --- Inscription ---
  final _registerFormKey = GlobalKey<FormState>();
  final _nomEntrepriseController = TextEditingController();
  final _regTelephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _typeCompte = 'TRANSPORTEUR';
  String _paysCompte = 'ML';
  bool _regPasswordVisible = false;
  bool _confirmVisible = false;
  bool _registerLoading = false;

  /// Numéro complet envoyé au backend, normalisé selon le plan de
  /// numérotation du pays choisi (indicatif + numéro national, zéro initial
  /// retiré si besoin). Ne doit être appelé qu'après validation du
  /// formulaire (le `validator:` du champ garantit déjà que ça ne lève pas).
  String get _telephoneInscriptionComplet {
    return normaliserTelephone(_paysCompte, _regTelephoneController.text.trim());
  }

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _t = CurvedAnimation(parent: _slide, curve: const Cubic(0.65, 0, 0.35, 1));

    // Le site vitrine (page publique, hors app) lie son bouton "Créer un
    // compte" vers l'app avec `?inscription=1` pour ouvrir directement le
    // formulaire d'inscription plutôt que la connexion.
    if (Uri.base.queryParameters['inscription'] == '1') {
      _isSignup = true;
      _slide.value = 1;
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _nomEntrepriseController.dispose();
    _regTelephoneController.dispose();
    _emailController.dispose();
    _regPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _messageErreur(String texte) => texte.replaceFirst('Exception: ', '');

  void _goToSignup() {
    if (_isSignup) return;
    setState(() => _isSignup = true);
    _slide.forward();
  }

  void _goToLogin() {
    if (!_isSignup) return;
    setState(() => _isSignup = false);
    _slide.reverse();
  }

  Future<void> _login() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _loginLoading = true);

    try {
      final result = await ApiService.login(
        _telephoneController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result["success"] == true) {
        final data = result["data"] ?? {};
        final user = data["user"];
        final token = data["access"];
        final refreshToken = data["refresh"];

        if (token != null) {
          await StorageService.saveToken(token.toString());
        }

        if (refreshToken != null) {
          await StorageService.saveRefreshToken(refreshToken.toString());
        }

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.authUserNotFound)),
          );
          return;
        }

        naviguerApresConnexion(
          context,
          Map<String, dynamic>.from(user),
          token?.toString() ?? "",
        );
        return;
      }

      // Pas un compte utilisateur classique : le chauffeur n'a pas de compte
      // séparé, il utilise le même formulaire (téléphone + le même champ, qui
      // joue le rôle de code d'accès) plutôt qu'un écran de connexion dédié.
      final chauffeurResult = await ApiService.chauffeurLogin(
        _telephoneController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (chauffeurResult["success"] == true) {
        final data = chauffeurResult["data"] ?? {};
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ChauffeurDashboardScreen(
              chauffeur: {
                'id': data['chauffeur_id'],
                'nom': data['nom'],
                'photo': data['photo'],
                // Rejoué à chaque action sensible côté Django (démarrer/
                // terminer une mission, position, photo) — chauffeur_id seul
                // est un entier devinable, cf. _refuser_si_mauvais_code_acces.
                'code_acces': _passwordController.text,
              },
            ),
          ),
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"] ?? l10n.authIncorrectCredentials,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageErreur('$e'))),
      );
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _creerCompte() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _registerLoading = true);

    final telephoneComplet = _telephoneInscriptionComplet;

    try {
      final inscription = await ApiService.register(
        telephone: telephoneComplet,
        password: _regPasswordController.text,
        typeCompte: _typeCompte,
        nomEntreprise: _nomEntrepriseController.text,
        email: _emailController.text,
        pays: _paysCompte,
      );

      if (!mounted) return;

      if (inscription['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              inscription['message'] ?? l10n.authSignupFailedGeneric,
            ),
          ),
        );
        return;
      }

      // Connexion automatique juste après l'inscription, pour éviter de
      // faire ressaisir les identifiants qu'on vient d'entrer. Doit utiliser
      // le même numéro composé (indicatif + local) que celui envoyé à
      // register() ci-dessus, puisque c'est ce qui a été stocké côté serveur.
      final connexion = await ApiService.login(
        telephoneComplet,
        _regPasswordController.text,
      );

      if (!mounted) return;

      final data = connexion['data'] ?? {};
      final user = data['user'];
      final token = data['access'];
      final refreshToken = data['refresh'];

      if (connexion['success'] != true || user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.authAccountCreatedPleaseLogin),
          ),
        );
        _goToLogin();
        return;
      }

      if (token != null) {
        await StorageService.saveToken(token.toString());
      }

      if (refreshToken != null) {
        await StorageService.saveRefreshToken(refreshToken.toString());
      }

      naviguerApresConnexion(
        context,
        Map<String, dynamic>.from(user),
        token?.toString() ?? '',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageErreur('$e'))),
      );
    } finally {
      if (mounted) setState(() => _registerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authInk,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, outer) {
              final isWide = outer.maxWidth >= _breakpoint;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 22,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: outer.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Sur une ligne à part plutôt que côte à côte avec
                          // le logo : en mobile étroit, les deux côte à côte
                          // se chevauchaient (le sélecteur, élargi par les
                          // drapeaux, entrait en collision avec "AfriFlotte").
                          SizedBox(
                            width: double.infinity,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: LanguageSwitcher(light: true),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const _BrandRow(),
                          const SizedBox(height: 28),
                          isWide ? _buildWideStage() : _buildNarrowStack(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideStage() {
    return LayoutBuilder(
      builder: (context, c) {
        final stageWidth = c.maxWidth > 920 ? 920.0 : c.maxWidth;
        final formWidth = stageWidth * 0.55;
        final coverWidth = stageWidth - formWidth;
        const stageHeight = 620.0;

        return Container(
          width: stageWidth,
          height: stageHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 50,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(
              color: authPaper,
              child: AnimatedBuilder(
                animation: _t,
                builder: (context, _) {
                  final t = _t.value;
                  return Stack(
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: lerpDouble(0, -formWidth - 60, t)!,
                        width: formWidth,
                        child: Opacity(
                          opacity: (1 - t).clamp(0.0, 1.0),
                          child: IgnorePointer(
                            ignoring: t > 0.5,
                            child: _formScroll(_loginFormContent()),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: lerpDouble(stageWidth + 60, stageWidth - formWidth, t)!,
                        width: formWidth,
                        child: Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: IgnorePointer(
                            ignoring: t < 0.5,
                            child: _formScroll(
                              _registerFormContent(),
                              key: const Key('auth_register_form_scroll'),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: lerpDouble(stageWidth - coverWidth, 0, t)!,
                        width: coverWidth,
                        child: _coverPanel(t),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNarrowStack() {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // `Offstage` plutôt que `IndexedStack` : les deux cartes gardent leur
        // état (texte déjà saisi) au bascule instantané connexion/inscription,
        // mais contrairement à `IndexedStack` — qui dimensionne toujours sa
        // boîte sur le plus grand des deux enfants — la carte masquée ne
        // compte pour aucune hauteur. Sans ça, l'écart entre le bas de la
        // carte visible et `AuthSwitchPanel` variait selon la carte (fixe car
        // calé sur la hauteur de la carte inscription, plus longue, même
        // quand c'est la carte connexion, plus courte, qui est affichée).
        Offstage(
          offstage: _isSignup,
          child: AuthCard(child: _loginFormContent()),
        ),
        Offstage(
          offstage: !_isSignup,
          child: AuthCard(child: _registerFormContent()),
        ),
        const SizedBox(height: 28),
        AuthSwitchPanel(
          title: _isSignup ? l10n.authSwitchToLoginTitle : l10n.authSwitchToSignupTitle,
          text: _isSignup ? l10n.authSwitchToLoginText : l10n.authSwitchToSignupText,
          buttonLabel: _isSignup ? l10n.authSwitchToLoginButton : l10n.authSwitchToSignupButton,
          onTap: _isSignup ? _goToLogin : _goToSignup,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _formScroll(Widget content, {Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(36, 40, 36, 36),
      child: content,
    );
  }

  Widget _coverPanel(double t) {
    final l10n = AppLocalizations.of(context);

    final radius = t < 0.5
        ? const BorderRadius.only(
            topLeft: Radius.circular(120),
            bottomLeft: Radius.circular(120),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(120),
            bottomRight: Radius.circular(120),
          );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [authPanelDark, authPanelTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      alignment: Alignment.centerLeft,
      child: AuthSwitchPanel(
        title: _isSignup ? l10n.authSwitchToLoginTitle : l10n.authSwitchToSignupTitle,
        text: _isSignup ? l10n.authSwitchToLoginText : l10n.authSwitchToSignupText,
        buttonLabel: _isSignup ? l10n.authSwitchToLoginButton : l10n.authSwitchToSignupButton,
        onTap: _isSignup ? _goToLogin : _goToSignup,
      ),
    );
  }

  Widget _loginFormContent() {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.authWelcomeBackEyebrow, style: authEyebrow()),
          const SizedBox(height: 8),
          Text(l10n.authLoginTitle, style: authHeading(size: 26)),
          const SizedBox(height: 6),
          Text(l10n.authLoginSubtitle, style: authBody()),
          const SizedBox(height: 26),
          TextFormField(
            key: const Key('auth_login_telephone'),
            controller: _telephoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: authBody(color: authTextDark, weight: FontWeight.w500),
            decoration: authInputDecoration(l10n.authPhoneLabel, Icons.phone_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return l10n.authPhoneRequired;
              return _telephoneLoginPlausible.hasMatch(value.trim())
                  ? null
                  : l10n.authPhoneInvalid;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('auth_login_password'),
            controller: _passwordController,
            obscureText: !_loginPasswordVisible,
            textInputAction: TextInputAction.done,
            style: authBody(color: authTextDark, weight: FontWeight.w500),
            onFieldSubmitted: (_) => _login(),
            decoration: authInputDecoration(
              l10n.authPasswordLabel,
              Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _loginPasswordVisible = !_loginPasswordVisible),
                icon: Icon(
                  _loginPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: authMintDim,
                ),
              ),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? l10n.authPasswordRequired : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MotDePasseOublieScreen()),
              ),
              style: TextButton.styleFrom(
                foregroundColor: authMintDim,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.authForgotPasswordLink,
                style: authBody(color: authMintDim, weight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AuthPrimaryButton(label: l10n.authLoginButton, loading: _loginLoading, onPressed: _login),
        ],
      ),
    );
  }

  Widget _registerFormContent() {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.authNewHereEyebrow, style: authEyebrow()),
          const SizedBox(height: 8),
          Text(l10n.authSignupTitle, style: authHeading(size: 25)),
          const SizedBox(height: 6),
          Text(l10n.authSignupSubtitle, style: authBody()),
          const SizedBox(height: 24),
          Text(
            l10n.authAccountTypeLabel,
            style: authBody(color: authTextDark, weight: FontWeight.w700, size: 13),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'TRANSPORTEUR',
                label: Text(l10n.authAccountTypeTransporteur),
                icon: const Icon(Icons.local_shipping_outlined),
              ),
              ButtonSegment(
                value: 'ENTREPRISE',
                label: Text(l10n.authAccountTypeEntreprise),
                icon: const Icon(Icons.business_outlined),
              ),
            ],
            selected: {_typeCompte},
            onSelectionChanged: (selection) => setState(() => _typeCompte = selection.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: authMintDim,
              selectedForegroundColor: Colors.white,
              side: const BorderSide(color: authPaperDim),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nomEntrepriseController,
            textCapitalization: TextCapitalization.words,
            style: authBody(color: authTextDark, weight: FontWeight.w500),
            decoration: authInputDecoration(
              l10n.authCompanyNameLabel,
              Icons.apartment_outlined,
            ),
          ),
          const SizedBox(height: 16),
          PaysDropdown(
            value: _paysCompte,
            label: l10n.modifierProfilCountry,
            onChanged: (value) => setState(() => _paysCompte = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('auth_register_telephone'),
            controller: _regTelephoneController,
            keyboardType: TextInputType.phone,
            style: authBody(color: authTextDark, weight: FontWeight.w500),
            decoration: authInputDecoration(l10n.authPhoneLabel, Icons.phone_outlined).copyWith(
              prefixText: '${indicatifParPays(_paysCompte) ?? ''} ',
              helperText: l10n.addChauffeurPhoneHelper,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return l10n.authPhoneRequired;
              return validerNumeroLocal(_paysCompte, value.trim());
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: authBody(color: authTextDark, weight: FontWeight.w500),
            decoration: authInputDecoration(l10n.authEmailLabel, Icons.mail_outline)
                .copyWith(helperText: l10n.authEmailHelper),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return l10n.authEmailRequired;
              return _emailValide.hasMatch(value.trim()) ? null : l10n.authEmailInvalid;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('auth_register_password'),
            controller: _regPasswordController,
            obscureText: !_regPasswordVisible,
            style: authBody(color: authTextDark, weight: FontWeight.w500),
            decoration: authInputDecoration(
              l10n.authPasswordLabel,
              Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _regPasswordVisible = !_regPasswordVisible),
                icon: Icon(
                  _regPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: authMintDim,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.authPasswordRequired;
              if (value.length < 6) return l10n.authPasswordMinLength;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_confirmVisible,
            textInputAction: TextInputAction.done,
            style: authBody(color: authTextDark, weight: FontWeight.w500),
            onFieldSubmitted: (_) => _creerCompte(),
            decoration: authInputDecoration(
              l10n.authConfirmPasswordLabel,
              Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _confirmVisible = !_confirmVisible),
                icon: Icon(
                  _confirmVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: authMintDim,
                ),
              ),
            ),
            validator: (value) =>
                value != _regPasswordController.text ? l10n.authPasswordMismatch : null,
          ),
          const SizedBox(height: 26),
          AuthPrimaryButton(
            label: l10n.authSignupButton,
            loading: _registerLoading,
            onPressed: _creerCompte,
          ),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: authMint.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: authMint.withValues(alpha: 0.4)),
          ),
          // ClipRRect : le logo a un fond blanc plein désormais, il lui
          // faut ses propres coins arrondis pour ne pas former un carré
          // dur dans le cadre arrondi.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset('assets/images/logo_icon.png'),
          ),
        ),
        const SizedBox(width: 12),
        Text('AfriFlotte', style: authHeading(color: Colors.white, size: 22)),
      ],
    );
  }
}
