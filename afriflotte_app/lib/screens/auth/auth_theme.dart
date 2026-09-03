import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette et widgets communs à l'écran d'authentification.
/// Reprend la charte navy/bleu déjà utilisée partout ailleurs dans l'app
/// (splash, dashboards, écran chauffeur : #071A3A / #102C5C / #38BDF8).
const authInk = Color(0xFF061429);
const authPanelDark = Color(0xFF061429);
const authPanelTeal = Color(0xFF0F2D5C);
const authMint = Color(0xFF5DD6FF);
const authMintDim = Color(0xFF1D4ED8);
const authPaper = Color(0xFFF7FAFE);
const authPaperDim = Color(0xFFD9E4F2);
const authTextDark = Color(0xFF10233D);
const authTextMute = Color(0xFF63758C);

TextStyle authEyebrow() => GoogleFonts.jetBrainsMono(
  fontSize: 11.5,
  letterSpacing: 2,
  fontWeight: FontWeight.w600,
  color: authMintDim,
);

TextStyle authHeading({Color color = authTextDark, double size = 26}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.5,
      height: 1.12,
    );

TextStyle authBody({
  Color color = authTextMute,
  double size = 13.5,
  FontWeight weight = FontWeight.w400,
}) => GoogleFonts.manrope(fontSize: size, color: color, fontWeight: weight);

InputDecoration authInputDecoration(
  String label,
  IconData icon, {
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.manrope(color: authTextMute, fontSize: 13.5),
    prefixIcon: Icon(icon, color: authMintDim, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: authPaperDim, width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: authPaperDim, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: authMintDim, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
  );
}

/// Fond sombre avec halos dégradés, à placer derrière le contenu défilant.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [authPanelDark, authPanelTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            left: -60,
            child: _glow(260, authMint.withValues(alpha: 0.16)),
          ),
          Positioned(
            top: 120,
            right: -80,
            child: _glow(220, authMintDim.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -110,
            right: -70,
            child: _glow(320, authMint.withValues(alpha: 0.10)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Carte "papier" flottante qui porte le formulaire (login ou inscription).
class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        color: authPaper,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Bouton principal en dégradé (équivalent du bouton "Connexion" / "Créer un compte").
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [authPanelDark, authPanelTeal],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: authMintDim.withValues(alpha: 0.32),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: loading ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Panneau "cover" : invite à basculer login <-> inscription, avec le même
/// esprit que le panneau glissant du design d'origine.
class AuthSwitchPanel extends StatelessWidget {
  final String title;
  final String text;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool light;

  const AuthSwitchPanel({
    super.key,
    required this.title,
    required this.text,
    required this.buttonLabel,
    required this.onTap,
    this.light = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : authTextDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(child: Text(title, style: authHeading(color: textColor, size: 20))),
            _BlinkingCursor(color: light ? authMint : authMintDim),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: authBody(color: light ? Colors.white.withValues(alpha: 0.75) : authTextMute),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: light ? Colors.white.withValues(alpha: 0.55) : authMintDim,
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
            foregroundColor: textColor,
          ),
          child: Text(
            buttonLabel,
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 3),
      child: FadeTransition(
        opacity: _controller,
        child: Container(width: 7, height: 18, color: widget.color),
      ),
    );
  }
}
