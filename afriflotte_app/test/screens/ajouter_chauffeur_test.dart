import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/l10n/generated/app_localizations.dart';
import 'package:afriflotte_app/screens/transporteur/chauffeurs/ajouter_chauffeur.dart';

void main() {
  testWidgets('shows required-field errors instead of calling the API', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        // AjouterChauffeur lit AppLocalizations.of(context) dès son premier
        // build : sans ce câblage (identique à main.dart), le test plantait
        // par un null-check sur une localisation absente de l'arbre. `locale`
        // fixé en français explicitement : sans lui, le test résout la
        // locale système par défaut (anglais dans ce binding), alors que les
        // assertions ci-dessous vérifient des libellés français.
        locale: Locale('fr'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AjouterChauffeur(token: 'test-token'),
      ),
    );

    // Le formulaire vit dans un SingleChildScrollView : depuis l'ajout du
    // sélecteur de pays, le bouton n'est plus dans le viewport par défaut du
    // test sans un scroll explicite au préalable (un vrai utilisateur, lui,
    // peut toujours faire défiler la page).
    final boutonEnregistrer = find.widgetWithText(ElevatedButton, 'Enregistrer');
    await tester.ensureVisible(boutonEnregistrer);
    await tester.tap(boutonEnregistrer);
    await tester.pump();

    expect(find.text('Le nom est obligatoire'), findsOneWidget);
    expect(find.text('Le téléphone est obligatoire'), findsOneWidget);
    expect(find.text('Le numéro de permis est obligatoire'), findsOneWidget);
  });
}
