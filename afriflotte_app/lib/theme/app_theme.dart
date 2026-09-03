import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AfriFlotte design tokens. Keeping the palette here makes every surface
/// react consistently when the user switches between light and dark mode.
abstract final class AfriFlotteColors {
  static const navy = Color(0xFF061429);
  static const navyMid = Color(0xFF0F2D5C);
  static const blue = Color(0xFF1D4ED8);
  static const cyan = Color(0xFF5DD6FF);
  static const ink = Color(0xFF10233D);
  static const muted = Color(0xFF63758C);
  static const lightBackground = Color(0xFFF2F6FC);
  static const darkBackground = Color(0xFF07111F);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF101E31);
  static const lightBorder = Color(0xFFE0E8F3);
  static const darkBorder = Color(0xFF263A54);
  static const success = Color(0xFF19B37D);
  static const warning = Color(0xFFE89A18);
  static const danger = Color(0xFFE05252);
}

abstract final class AfriFlotteTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? AfriFlotteColors.cyan : AfriFlotteColors.navyMid,
      onPrimary: dark ? AfriFlotteColors.navy : Colors.white,
      secondary: dark ? AfriFlotteColors.cyan : AfriFlotteColors.blue,
      onSecondary: dark ? AfriFlotteColors.navy : Colors.white,
      tertiary: dark ? const Color(0xFF8CE7FF) : AfriFlotteColors.cyan,
      onTertiary: AfriFlotteColors.navy,
      error: AfriFlotteColors.danger,
      onError: Colors.white,
      surface: dark ? AfriFlotteColors.darkSurface : AfriFlotteColors.lightSurface,
      onSurface: dark ? const Color(0xFFE8F0FA) : AfriFlotteColors.ink,
      surfaceContainerHighest: dark
          ? const Color(0xFF1B2B41)
          : const Color(0xFFEDF3FA),
      onSurfaceVariant: dark ? const Color(0xFFB4C2D5) : AfriFlotteColors.muted,
      outline: dark ? AfriFlotteColors.darkBorder : AfriFlotteColors.lightBorder,
      outlineVariant: dark
          ? const Color(0xFF304762)
          : const Color(0xFFD4DFEC),
      inverseSurface: dark ? const Color(0xFFE8F0FA) : AfriFlotteColors.navy,
      onInverseSurface: dark ? AfriFlotteColors.navy : Colors.white,
      inversePrimary: dark ? AfriFlotteColors.blue : AfriFlotteColors.cyan,
      scrim: Colors.black,
    );

    final baseText = GoogleFonts.manropeTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );
    final displayText = GoogleFonts.frauncesTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? AfriFlotteColors.darkBackground : AfriFlotteColors.lightBackground,
      textTheme: baseText
          .copyWith(
            displayLarge: displayText.displayLarge,
            displayMedium: displayText.displayMedium,
            displaySmall: displayText.displaySmall,
            headlineLarge: displayText.headlineLarge,
            headlineMedium: displayText.headlineMedium,
            headlineSmall: displayText.headlineSmall,
          )
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: dark ? AfriFlotteColors.navy : AfriFlotteColors.navyMid,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF13243A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
        border: _inputBorder(scheme.outline),
        enabledBorder: _inputBorder(scheme.outline),
        focusedBorder: _inputBorder(scheme.secondary, width: 1.7),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.7),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(scheme, filled: true),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(scheme, filled: true),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(scheme, filled: false),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.secondary,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFFE8F0FA) : AfriFlotteColors.ink,
        contentTextStyle: GoogleFonts.manrope(
          color: dark ? AfriFlotteColors.ink : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: color, width: width),
      );

  static ButtonStyle _buttonStyle(ColorScheme scheme, {required bool filled}) =>
      ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: filled
            ? WidgetStatePropertyAll(scheme.secondary)
            : null,
        foregroundColor: filled
            ? WidgetStatePropertyAll(scheme.onSecondary)
            : WidgetStatePropertyAll(scheme.secondary),
        side: filled
            ? null
            : WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
      );
}
