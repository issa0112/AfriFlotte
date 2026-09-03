import 'package:flutter/material.dart';

const _navyDark = Color(0xFF071A3A);
const _navyMid = Color(0xFF102C5C);
const _accent = Color(0xFF2563EB);

/// Une destination de la sidebar — présentation seule, la sélection et la
/// navigation restent gérées par l'appelant (`onTap`).
class AppSidebarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppSidebarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

/// Sidebar de marque pour desktop/tablette — même charte que
/// `LiquidBottomNav` (dégradé navy, accent bleu), en version compacte
/// (icônes seules) ou étendue (icônes + libellés). Purement présentationnelle
/// : ne gère aucun état de sélection elle-même, réutilisable aussi bien par
/// un écran à onglets (`AdaptiveShell`) que par un hub qui se contente de
/// pousser vers des écrans de détail (`DashboardAdmin`), où aucune entrée
/// n'est jamais "sélectionnée" en permanence.
class AppSidebar extends StatelessWidget {
  final List<AppSidebarItem> items;
  final bool etendue;

  const AppSidebar({super.key, required this.items, required this.etendue});

  static const double largeurCompacte = 76;
  static const double largeurEtendue = 240;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: etendue ? largeurEtendue : largeurCompacte,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navyDark, _navyMid],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: etendue
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _logo(),
                        const SizedBox(width: 10),
                        const Text(
                          'AfriFlotte',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : Center(child: _logo()),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [for (final item in items) _entree(item)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset('assets/images/logo_icon.png', width: 30, height: 30),
    );
  }

  Widget _entree(AppSidebarItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: item.selected
            ? _accent.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: item.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: etendue ? 14 : 0,
              vertical: 13,
            ),
            child: Row(
              mainAxisAlignment: etendue
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  item.selected ? (item.activeIcon ?? item.icon) : item.icon,
                  color: item.selected ? Colors.white : Colors.white60,
                  size: 22,
                ),
                if (etendue) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.selected ? Colors.white : Colors.white60,
                        fontWeight: item.selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
