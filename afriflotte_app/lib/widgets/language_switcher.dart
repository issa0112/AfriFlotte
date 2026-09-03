import 'package:flutter/material.dart';

import '../l10n/locale_controller.dart';

const _navyDark = Color(0xFF102C5C);
const _accent = Color(0xFF2563EB);

/// Sélecteur de langue FR/EN — pilule avec indicateur dégradé (charte de
/// l'app) qui glisse avec un léger rebond, drapeaux + code, retour tactile
/// au clic. `light: true` pour un usage sur fond sombre (écran
/// d'authentification, tableau de bord chauffeur), `false` (défaut) pour
/// fond clair (écrans profil).
class LanguageSwitcher extends StatelessWidget {
  final bool light;

  const LanguageSwitcher({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final estFrancais = locale.languageCode == 'fr';

    final fond = light ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF1F5F9);
    final bordure = light ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFE2E8F0);
    final texteInactif = light ? Colors.white70 : const Color(0xFF64748B);

    // `IntrinsicWidth` : sans lui, dès que le parent offre une largeur
    // bornée mais généreuse (ex. `Align` sur toute la largeur de l'écran de
    // connexion), l'`AnimatedAlign` de l'indicateur — qui n'a pas de
    // `widthFactor` — s'étire pour la remplir entièrement au lieu de rester
    // compact, étirant toute la pilule et désynchronisant indicateur/texte.
    // `IntrinsicWidth` force ce sous-arbre à toujours mesurer sa largeur
    // naturelle, quel que soit ce que le parent propose.
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: bordure, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: light ? 0.12 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              alignment: estFrancais ? Alignment.centerLeft : Alignment.centerRight,
              // Largeur fixe (calée sur celle d'une `_Option`), pas relative
              // au parent : sous `IntrinsicWidth`, un `widthFactor` relatif
              // se recalculerait en boucle sur une largeur qui dépend de
              // lui-même — une valeur fixe évite toute ambiguïté.
              child: Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_navyDark, _accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Option(
                  flag: '🇫🇷',
                  label: 'FR',
                  active: estFrancais,
                  inactiveColor: texteInactif,
                  onTap: () => LocaleController.changer(const Locale('fr')),
                ),
                _Option(
                  flag: '🇬🇧',
                  label: 'EN',
                  active: !estFrancais,
                  inactiveColor: texteInactif,
                  onTap: () => LocaleController.changer(const Locale('en')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatefulWidget {
  final String flag;
  final String label;
  final bool active;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _Option({
    required this.flag,
    required this.label,
    required this.active,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 60,
          height: 32,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.flag, style: const TextStyle(fontSize: 13, height: 1)),
                const SizedBox(width: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: widget.active ? Colors.white : widget.inactiveColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    letterSpacing: 0.3,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
