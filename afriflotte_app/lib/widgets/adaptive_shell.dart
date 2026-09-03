import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'app_sidebar.dart';
import 'liquid_bottom_nav.dart';

/// Destination d'`AdaptiveShell` — mêmes champs que `LiquidNavItem`, dont
/// c'est le pendant pour desktop/tablette (voir `AppSidebar`).
class AdaptiveNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const AdaptiveNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Enveloppe un écran à onglets pour qu'il s'affiche avec `LiquidBottomNav`
/// sur mobile (rendu strictement identique à l'existant — l'app n'a jamais eu
/// que ce cas avant ce module) et avec une `AppSidebar` sur tablette/desktop,
/// sans bottom nav. `page` est le contenu déjà sélectionné par l'appelant
/// (typiquement `pages[index]`) : cette enveloppe ne connaît que le chrome de
/// navigation, jamais le contenu des onglets eux-mêmes.
class AdaptiveShell extends StatelessWidget {
  final List<AdaptiveNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget page;
  final Color? backgroundColor;

  const AdaptiveShell({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.page,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final formFactor = formFactorOf(context);
    final shellBackground =
        backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    if (formFactor == FormFactor.mobile) {
      return Scaffold(
        backgroundColor: shellBackground,
        extendBody: true,
        body: page,
        bottomNavigationBar: LiquidBottomNav(
          currentIndex: currentIndex,
          onTap: onTap,
          items: [
            for (final item in items)
              LiquidNavItem(
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: shellBackground,
      body: Row(
        children: [
          AppSidebar(
            etendue: formFactor == FormFactor.desktop,
            items: [
              for (var i = 0; i < items.length; i++)
                AppSidebarItem(
                  icon: items[i].icon,
                  activeIcon: items[i].activeIcon,
                  label: items[i].label,
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
          Expanded(
            child: BoundedContent(
              padding: const EdgeInsets.all(8),
              child: page,
            ),
          ),
        ],
      ),
    );
  }
}
