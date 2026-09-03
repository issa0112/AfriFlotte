import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/widgets/liquid_bottom_nav.dart';

const _items = [
  LiquidNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Accueil'),
  LiquidNavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Camions'),
  LiquidNavItem(icon: Icons.badge_outlined, activeIcon: Icons.badge, label: 'Chauffeurs'),
  LiquidNavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Missions'),
  LiquidNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
];

class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: const SizedBox(),
        bottomNavigationBar: LiquidBottomNav(
          currentIndex: index,
          onTap: (value) => setState(() => index = value),
          items: _items,
        ),
      ),
    );
  }
}

void main() {
  testWidgets('renders the active label and does not throw', (tester) async {
    await tester.pumpWidget(const _Harness());

    expect(find.text('Accueil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a slot switches the active tab and animates without throwing', (tester) async {
    await tester.pumpWidget(const _Harness());

    // Le libellé "Missions" n'apparaît que sous la bulle active : tant que ce
    // n'est pas l'onglet sélectionné, seule son icône (dans la rangée) existe.
    await tester.tap(find.byIcon(Icons.assignment_outlined));
    // Pompe quelques frames pendant l'animation du glissement (500ms) pour
    // s'assurer que le CustomPainter ne casse pas à mi-course (positions
    // fractionnaires, notch qui traverse plusieurs slots).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Missions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid successive taps do not throw mid-animation', (tester) async {
    await tester.pumpWidget(const _Harness());

    await tester.tap(find.byIcon(Icons.badge_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Profil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
