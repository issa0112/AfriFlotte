import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// État global de la langue de l'app — un simple `ValueNotifier` suffit ici
/// (pas besoin d'un package de gestion d'état plus lourd pour une seule
/// valeur partagée) : `main.dart` écoute ce notifier et reconstruit tout
/// `MaterialApp` quand la langue change, où qu'on soit dans la navigation.
class LocaleController {
  LocaleController._();

  static const _prefsKey = 'langue_app';

  /// `null` = suit la langue du système tant que l'utilisateur n'a rien
  /// choisi explicitement.
  static final ValueNotifier<Locale?> locale = ValueNotifier(null);

  static Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null) {
      locale.value = Locale(code);
    }
  }

  static Future<void> changer(Locale nouvelleLocale) async {
    locale.value = nouvelleLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, nouvelleLocale.languageCode);
  }
}
