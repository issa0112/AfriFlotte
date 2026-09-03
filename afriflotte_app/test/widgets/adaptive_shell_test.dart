import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/widgets/adaptive_shell.dart';
import 'package:afriflotte_app/widgets/app_sidebar.dart';
import 'package:afriflotte_app/widgets/liquid_bottom_nav.dart';

const _items = [
  AdaptiveNavItem(icon: Icons.home_outlined, label: 'Accueil'),
  AdaptiveNavItem(icon: Icons.list_outlined, label: 'Liste'),
];

Widget _shell(int index, ValueChanged<int> onTap) {
  return MaterialApp(
    home: AdaptiveShell(
      items: _items,
      currentIndex: index,
      onTap: onTap,
      page: const Text('contenu'),
    ),
  );
}

void main() {
  testWidgets('largeur mobile : LiquidBottomNav visible, pas de sidebar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_shell(0, (_) {}));

    expect(find.byType(LiquidBottomNav), findsOneWidget);
    expect(find.byType(AppSidebar), findsNothing);
  });

  testWidgets('largeur tablette : sidebar compacte visible, pas de bottom nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_shell(0, (_) {}));

    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.byType(LiquidBottomNav), findsNothing);

    final sidebar = tester.widget<AppSidebar>(find.byType(AppSidebar));
    expect(sidebar.etendue, isFalse);
  });

  testWidgets('largeur desktop : sidebar étendue visible', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_shell(0, (_) {}));

    final sidebar = tester.widget<AppSidebar>(find.byType(AppSidebar));
    expect(sidebar.etendue, isTrue);
  });

  testWidgets('taper une entrée de la sidebar déclenche onTap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int? tapped;
    await tester.pumpWidget(_shell(0, (i) => tapped = i));

    await tester.tap(find.text('Liste'));
    await tester.pump();

    expect(tapped, 1);
  });
}
