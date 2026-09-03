import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

class ThemeSwitcher extends StatelessWidget {
  final bool light;

  const ThemeSwitcher({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        final sombre = mode == ThemeMode.dark;
        return IconButton(
          tooltip: sombre ? 'Mode clair' : 'Mode sombre',
          onPressed: ThemeController.basculer,
          style: IconButton.styleFrom(
            foregroundColor: light ? Colors.white : null,
            backgroundColor: light
                ? Colors.white.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          icon: Icon(sombre ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
        );
      },
    );
  }
}
