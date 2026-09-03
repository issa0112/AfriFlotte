import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/l10n/generated/app_localizations.dart';
import 'package:afriflotte_app/screens/auth/auth_screen.dart';
import 'package:afriflotte_app/screens/auth/auth_theme.dart';

// AuthScreen lit AppLocalizations.of(context) dès son premier build : sans ce
// câblage (identique à main.dart), le test plantait par un null-check sur une
// localisation absente de l'arbre. `locale` fixé en français explicitement :
// sans lui, le test résout la locale système par défaut (anglais dans ce
// binding), alors que les assertions ci-dessous vérifient des libellés
// français.
const _authScreenApp = MaterialApp(
  locale: Locale('fr'),
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: AuthScreen(),
);

/// Comme pour les anciens écrans séparés, on ne teste que la validation
/// locale : les services HTTP ne sont pas mockables ici (méthodes statiques
/// appelant http.get/post directement, pas de http.Client injectable).
///
/// AuthScreen garde les deux formulaires montés en permanence (pour ne pas
/// perdre la saisie en basculant), donc des libellés comme "Téléphone" ou
/// "Mot de passe" existent deux fois dans l'arbre : on cible les champs par
/// clé plutôt que par texte pour éviter toute ambiguïté.
///
/// La largeur de test par défaut (800x600) déclenche la mise en page large
/// (panneau qui glisse) : on l'utilise pour les tests qui portent sur le
/// glissement lui-même. Pour les tests de validation de formulaire, on force
/// une largeur étroite (<760) qui bascule sur l'IndexedStack mobile — pas
/// d'animation ni de Positioned/Opacity imbriqués à négocier, juste un
/// changement d'index instantané, ce qui rend le clic sur les champs et
/// boutons du formulaire d'inscription fiable en test.
const _dureeGlissement = Duration(milliseconds: 900);

void main() {
  const loginTelephone = Key('auth_login_telephone');
  const loginPassword = Key('auth_login_password');
  const registerTelephone = Key('auth_register_telephone');
  const registerPassword = Key('auth_register_password');

  Finder boutonInscription() => find.widgetWithText(OutlinedButton, "S'inscrire");
  Finder boutonConnexionSwitch() => find.widgetWithText(OutlinedButton, 'Se connecter');
  Finder boutonCreerCompte() => find.widgetWithText(AuthPrimaryButton, 'Créer mon compte');

  // Un unique `pump(duree)` juste après `tap()` ne suffit pas : il faut un
  // premier `pump()` à durée nulle pour que le callback `onTap` (qui déclenche
  // le `setState`/`AnimationController.forward()`) s'exécute avant que
  // l'horloge n'avance et ne fasse "glisser" le panneau.
  Future<void> basculer(WidgetTester tester, Finder bouton) async {
    await tester.tap(bouton);
    await tester.pump();
    await tester.pump(_dureeGlissement);
  }

  Future<void> pumpEtroit(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_authScreenApp);
  }

  testWidgets('shows the login form by default', (tester) async {
    await tester.pumpWidget(_authScreenApp);

    expect(find.text('AfriFlotte'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.widgetWithText(AuthPrimaryButton, 'Connexion'), findsOneWidget);
  });

  testWidgets('shows inline validation errors when submitting empty login fields', (tester) async {
    await tester.pumpWidget(_authScreenApp);

    await tester.tap(find.widgetWithText(AuthPrimaryButton, 'Connexion'));
    await tester.pump();

    expect(find.text('Le téléphone est obligatoire'), findsOneWidget);
    expect(find.text('Le mot de passe est obligatoire'), findsOneWidget);
  });

  testWidgets('toggles login password visibility', (tester) async {
    await tester.pumpWidget(_authScreenApp);

    final icone = find.descendant(
      of: find.byKey(loginPassword),
      matching: find.byIcon(Icons.visibility_outlined),
    );
    expect(icone, findsOneWidget);

    await tester.tap(icone);
    await tester.pump();

    expect(
      find.descendant(of: find.byKey(loginPassword), matching: find.byIcon(Icons.visibility_off_outlined)),
      findsOneWidget,
    );
  });

  testWidgets('sliding to the signup panel reveals both account types', (tester) async {
    await tester.pumpWidget(_authScreenApp);

    await basculer(tester, boutonInscription());

    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Transporteur'), findsOneWidget);
    expect(find.text('Entreprise'), findsOneWidget);
  });

  testWidgets('switching back and forth preserves the typed phone number (wide layout)', (tester) async {
    await tester.pumpWidget(_authScreenApp);

    await tester.enterText(find.byKey(loginTelephone), '70707070');

    await basculer(tester, boutonInscription());
    await basculer(tester, boutonConnexionSwitch());

    expect(find.text('70707070'), findsOneWidget);
  });

  testWidgets('shows required-field errors instead of calling the API', (tester) async {
    await pumpEtroit(tester);

    await tester.tap(boutonInscription());
    await tester.pump();

    await tester.tap(boutonCreerCompte());
    await tester.pump();

    expect(find.text('Le téléphone est obligatoire'), findsOneWidget);
    expect(find.text('Le mot de passe est obligatoire'), findsOneWidget);
  });

  testWidgets('rejects mismatched password confirmation', (tester) async {
    await pumpEtroit(tester);

    await tester.tap(boutonInscription());
    await tester.pump();

    await tester.enterText(find.byKey(registerTelephone), '70000001');
    await tester.enterText(find.byKey(registerPassword), 'secret123');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
      'autrechose',
    );

    await tester.tap(boutonCreerCompte());
    await tester.pump();

    expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);
  });

  testWidgets('switching account type does not throw', (tester) async {
    await pumpEtroit(tester);

    await tester.tap(boutonInscription());
    await tester.pump();

    await tester.tap(find.text('Entreprise'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('switching back and forth preserves the typed phone number (narrow layout)', (tester) async {
    await pumpEtroit(tester);

    await tester.enterText(find.byKey(loginTelephone), '70707070');

    await tester.tap(boutonInscription());
    await tester.pump();
    await tester.tap(boutonConnexionSwitch());
    await tester.pump();

    expect(find.text('70707070'), findsOneWidget);
  });
}
