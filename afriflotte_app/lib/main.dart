import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/generated/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await LocaleController.charger();
  await ThemeController.charger();

  runApp(
    const AfriFlotteApp()
  );

}


class AfriFlotteApp extends StatelessWidget {

  const AfriFlotteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (context, themeMode, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AfriFlotte',
            locale: locale,
            themeMode: themeMode,
            theme: AfriFlotteTheme.light(),
            darkTheme: AfriFlotteTheme.dark(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
