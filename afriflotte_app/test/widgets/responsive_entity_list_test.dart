import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/widgets/responsive_entity_list.dart';

class _Personne {
  final String nom;
  final int age;
  const _Personne(this.nom, this.age);
}

const _items = [_Personne('Zoé', 40), _Personne('Adama', 25), _Personne('Fatou', 32)];

List<TableColumn<_Personne>> _colonnes() => [
  TableColumn<_Personne>(
    label: 'Nom',
    cell: (p) => DataCell(Text(p.nom)),
    sortBy: (a, b) => a.nom.compareTo(b.nom),
  ),
  TableColumn<_Personne>(
    label: 'Âge',
    cell: (p) => DataCell(Text('${p.age}')),
    sortBy: (a, b) => a.age.compareTo(b.age),
    numeric: true,
  ),
];

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('mobile : affiche les cartes, pas de DataTable', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        ResponsiveEntityList<_Personne>(
          items: _items,
          mobileCardBuilder: (context, p) => Text('carte-${p.nom}'),
          columns: _colonnes(),
        ),
      ),
    );

    expect(find.text('carte-Zoé'), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
  });

  testWidgets('desktop : affiche une DataTable avec toutes les lignes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        ResponsiveEntityList<_Personne>(
          items: _items,
          mobileCardBuilder: (context, p) => Text('carte-${p.nom}'),
          columns: _colonnes(),
        ),
      ),
    );

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Zoé'), findsOneWidget);
    expect(find.text('Adama'), findsOneWidget);
    expect(find.text('Fatou'), findsOneWidget);
  });

  testWidgets('desktop : taper l\'en-tête trie la colonne', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        ResponsiveEntityList<_Personne>(
          items: _items,
          mobileCardBuilder: (context, p) => Text('carte-${p.nom}'),
          columns: _colonnes(),
        ),
      ),
    );

    // Ordre initial (non trié) : Zoé apparaît au-dessus d'Adama.
    expect(
      tester.getTopLeft(find.text('Zoé')).dy <
          tester.getTopLeft(find.text('Adama')).dy,
      isTrue,
    );

    await tester.tap(find.text('Nom'));
    await tester.pumpAndSettle();

    // Trié par ordre alphabétique : Adama passe au-dessus de Zoé.
    expect(
      tester.getTopLeft(find.text('Adama')).dy <
          tester.getTopLeft(find.text('Zoé')).dy,
      isTrue,
    );
  });

  testWidgets('taper une ligne déclenche onRowTap', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    _Personne? tapped;
    await tester.pumpWidget(
      _wrap(
        ResponsiveEntityList<_Personne>(
          items: _items,
          mobileCardBuilder: (context, p) => Text('carte-${p.nom}'),
          columns: _colonnes(),
          onRowTap: (p) => tapped = p,
        ),
      ),
    );

    await tester.tap(find.text('Fatou'));
    await tester.pump();

    expect(tapped?.nom, 'Fatou');
  });
}
