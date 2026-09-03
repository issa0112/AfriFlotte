import 'package:flutter_test/flutter_test.dart';

import 'package:afriflotte_app/main.dart';

void main() {
  testWidgets('AfriFlotte app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const AfriFlotteApp());

    expect(find.text('AfriFlotte'), findsOneWidget);

    // SplashScreen programme sa navigation via Future.delayed(3s) : sans
    // avancer l'horloge de test au-delà, ce timer reste en attente à la fin
    // du test et flutter_test échoue sur "A Timer is still pending".
    await tester.pump(const Duration(seconds: 3));
  });
}
