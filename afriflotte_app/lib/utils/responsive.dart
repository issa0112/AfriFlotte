import 'package:flutter/widgets.dart';

/// Points de rupture partagés par toute l'app — le même principe que
/// `auth_screen.dart` (760px, seul endroit à avoir une logique responsive
/// avant ce module), généralisé. Réagit à la largeur disponible, jamais à la
/// plateforme (`kIsWeb`) : un navigateur mobile étroit et l'APK Android
/// doivent se comporter pareil, seule la largeur compte.
enum FormFactor { mobile, tablet, desktop }

const double kLargeurTablette = 700;
const double kLargeurDesktop = 1024;

FormFactor formFactorForWidth(double largeur) {
  if (largeur >= kLargeurDesktop) return FormFactor.desktop;
  if (largeur >= kLargeurTablette) return FormFactor.tablet;
  return FormFactor.mobile;
}

FormFactor formFactorOf(BuildContext context) =>
    formFactorForWidth(MediaQuery.of(context).size.width);

/// Empêche le contenu existant (pensé pour un écran de téléphone) de
/// s'étirer bord à bord sur un grand écran : centre et plafonne la largeur.
/// No-op visuel sur mobile (la largeur de l'écran est de toute façon très en
/// dessous de `maxWidth`).
class BoundedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const BoundedContent({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
