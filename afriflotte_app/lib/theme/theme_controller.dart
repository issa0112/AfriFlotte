import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class ThemeController {
  static const _key = 'afriflotte_theme_mode';
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> charger() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_key);
    mode.value = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> definir(ThemeMode value) async {
    mode.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, value.name);
  }

  static Future<void> basculer() async {
    await definir(mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
