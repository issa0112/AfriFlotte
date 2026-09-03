import 'package:flutter/material.dart';

const _navyDark = Color(0xFF071A3A);
const _navyMid = Color(0xFF102C5C);
const _accentStart = Color(0xFF2563EB);
const _accentEnd = Color(0xFF38BDF8);

class LiquidNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const LiquidNavItem({required this.icon, this.activeIcon, required this.label});
}

/// Barre de navigation basse "liquide" : l'onglet actif se détache dans une
/// bulle flottante au-dessus de la barre, qui se creuse d'une vague lisse
/// pour l'accueillir. Remplace `BottomNavigationBar` / `NavigationBar` là où
/// on veut cet effet, avec la charte navy/bleu de l'app.
class LiquidBottomNav extends StatefulWidget {
  final List<LiquidNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const LiquidBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  // Hauteur totale occupée par la barre (bulle flottante comprise), hors
  // safe-area : à utiliser par les écrans qui placent un FloatingActionButton
  // sur une page affichée derrière cette barre (`Scaffold.extendBody`), pour
  // que le bouton ne se retrouve pas caché sous elle.
  static const double height = _LiquidBottomNavState._barHeight +
      _LiquidBottomNavState._extraTopSpace;

  @override
  State<LiquidBottomNav> createState() => _LiquidBottomNavState();
}

class _LiquidBottomNavState extends State<LiquidBottomNav>
    with SingleTickerProviderStateMixin {
  static const _barHeight = 68.0;
  static const _bubbleSize = 56.0;
  static const _extraTopSpace = 30.0;

  late final AnimationController _controller;
  late Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _position = AlwaysStoppedAnimation(widget.currentIndex.toDouble());
  }

  @override
  void didUpdateWidget(covariant LiquidBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final from = _position.value;
      _position = Tween<double>(begin: from, end: widget.currentIndex.toDouble())
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: _barHeight + _extraTopSpace,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final slotWidth = barWidth / widget.items.length;

            return AnimatedBuilder(
              animation: _position,
              builder: (context, _) {
                final activePos = _position.value;
                final notchX = slotWidth * (activePos + 0.5);
                // La bulle affiche déjà l'icône de destination pendant le
                // glissement : elle "devient" le nouvel onglet dès le tap.
                final roundedActive = widget.currentIndex;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CustomPaint(
                        size: Size(barWidth, _barHeight),
                        painter: _LiquidBarPainter(notchX: notchX),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _barHeight,
                      child: Row(
                        children: List.generate(widget.items.length, (i) {
                          final distance = (i - activePos).abs();
                          final faded = distance < 0.5;
                          return Expanded(
                            child: InkWell(
                              onTap: () => widget.onTap(i),
                              child: Center(
                                child: AnimatedOpacity(
                                  opacity: faded ? 0 : 1,
                                  duration: const Duration(milliseconds: 180),
                                  child: Icon(
                                    widget.items[i].icon,
                                    color: Colors.white70,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Positioned(
                      left: notchX - _bubbleSize / 2,
                      top: 0,
                      width: _bubbleSize,
                      child: GestureDetector(
                        onTap: () => widget.onTap(roundedActive),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: _bubbleSize,
                              height: _bubbleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [_accentStart, _accentEnd],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accentEnd.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(color: _navyDark, width: 3),
                              ),
                              child: Icon(
                                widget.items[roundedActive].activeIcon ??
                                    widget.items[roundedActive].icon,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.items[roundedActive].label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LiquidBarPainter extends CustomPainter {
  final double notchX;

  static const _notchRadius = 34.0;
  static const _cornerRadius = 26.0;

  _LiquidBarPainter({required this.notchX});

  @override
  void paint(Canvas canvas, Size size) {
    final r = _cornerRadius;
    final notchW = _notchRadius * 1.9;
    final dipDepth = _notchRadius * 0.62;

    final left = (notchX - notchW).clamp(r, size.width - r);
    final right = (notchX + notchW).clamp(r, size.width - r);

    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(left, 0)
      ..cubicTo(
        left + (notchX - left) * 0.5,
        0,
        notchX - _notchRadius,
        dipDepth,
        notchX,
        dipDepth,
      )
      ..cubicTo(
        notchX + _notchRadius,
        dipDepth,
        right - (right - notchX) * 0.5,
        0,
        right,
        0,
      )
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..close();

    canvas.drawShadow(path, Colors.black, 14, false);

    // Aplat (pas de dégradé propre à la barre) : un dégradé calculé sur la
    // petite boîte de la barre (68px) ne tombe jamais exactement sur les
    // mêmes pixels qu'un dégradé identique calculé sur la hauteur d'une page
    // entière (accueil entreprise, GPS transporteur utilisent ces mêmes deux
    // couleurs) — visible comme une barre "qui ne raccorde pas". `_navyMid`
    // seul est déjà la couleur navy standard des AppBar de l'app, donc se
    // fond naturellement avec le bas de ces pages en dégradé.
    final paint = Paint()..color = _navyMid;
    canvas.drawPath(path, paint);

    // Liseré clair fin : sans lui, la barre disparaît visuellement sur les
    // pages qui ont elles-mêmes un fond dégradé navy (accueil entreprise,
    // GPS transporteur) — même famille de bleu que la barre, donc plus
    // aucune séparation entre "barre flottante" et "page qui défile derrière"
    // une fois le contenu étendu sous elle (`extendBody`).
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _LiquidBarPainter oldDelegate) =>
      oldDelegate.notchX != notchX;
}
