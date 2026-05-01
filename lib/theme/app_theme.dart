import 'package:flutter/material.dart';

// Top-level notifier untuk toggle light/dark mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class AppTheme {
  // ─── Color Palette (SacredHub Design System) ─────────────────────────────
  static const Color primary = Color(0xFF004F45);
  static const Color primaryContainer = Color(0xFF00695C);
  static const Color primaryFixed = Color(0xFFA0F2E1);
  static const Color primaryFixedDim = Color(0xFF84D5C5);
  static const Color inversePrimary = Color(0xFF84D5C5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF94E5D5);
  static const Color onPrimaryFixed = Color(0xFF00201B);

  static const Color secondary = Color(0xFF875200);
  static const Color secondaryContainer = Color(0xFFF89C00);
  static const Color secondaryFixed = Color(0xFFFFDDBA);
  static const Color secondaryFixedDim = Color(0xFFFFB865);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF623A00);
  static const Color onSecondaryFixed = Color(0xFF2B1700);

  static const Color tertiary = Color(0xFF283B9F);
  static const Color tertiaryContainer = Color(0xFF4254B8);
  static const Color tertiaryFixed = Color(0xFFDEE0FF);
  static const Color tertiaryFixedDim = Color(0xFFBAC3FF);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFCFD4FF);
  static const Color onTertiaryFixed = Color(0xFF00105C);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceDim = Color(0xFFDADADA);
  static const Color surfaceVariant = Color(0xFFE2E2E2);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);

  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF3E4946);
  static const Color outline = Color(0xFF6E7976);
  static const Color outlineVariant = Color(0xFFBEC9C5);

  static const Color background = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF1A1C1C);

  // Dark mode equivalents
  static const Color bgDark = Color(0xFF0F1514);
  static const Color surfaceDark = Color(0xFF1A1C1C);

  // ─── Light Theme ─────────────────────────────────────────────────────────
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceContainerHighest,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceContainerLowest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: outline),
        hintStyle: const TextStyle(color: outline),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: outline,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 48,
          color: onSurface,
          fontFamily: 'Inter',
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurface,
          fontFamily: 'Inter',
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurface,
          fontFamily: 'Inter',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
          fontFamily: 'Inter',
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.05 * 11,
          color: onSurfaceVariant,
          fontFamily: 'Inter',
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inverseSurface,
        contentTextStyle: const TextStyle(color: inverseOnSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: surfaceContainerLowest,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLow,
        selectedColor: primaryContainer.withValues(alpha: 0.2),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: outlineVariant),
      ),
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  // Dark mode: bg=#1a1c1c, text=#f1f1f1 for maximum contrast
  static const Color _darkBg = Color(0xFF1A1C1C);
  static const Color _darkSurface = Color(0xFF252828);
  static const Color _darkText = Color(0xFFF1F1F1);
  static const Color _darkSubText = Color(0xFF889390);
  static const Color _darkBorder = Color(0xFF3A3C3C);

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: inversePrimary,
        onPrimary: Color(0xFF00201B),
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondaryFixedDim,
        onSecondary: onSecondaryFixed,
        secondaryContainer: Color(0xFF663D00),
        onSecondaryContainer: secondaryFixed,
        tertiary: tertiaryFixedDim,
        onTertiary: onTertiaryFixed,
        tertiaryContainer: Color(0xFF293CA0),
        onTertiaryContainer: tertiaryFixed,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        surface: _darkSurface,
        onSurface: _darkText,           // #f1f1f1 — high contrast
        surfaceContainerHighest: Color(0xFF3A3C3C),
        outline: _darkSubText,
        outlineVariant: _darkBorder,
      ),
      scaffoldBackgroundColor: _darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _darkSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: inversePrimary,
          foregroundColor: Color(0xFF00201B),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: inversePrimary,
          side: const BorderSide(color: inversePrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: inversePrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: _darkSubText),
        hintStyle: const TextStyle(color: _darkSubText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: inversePrimary,
        unselectedItemColor: _darkSubText,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _darkText,
          fontFamily: 'Inter',
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _darkText,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _darkText,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _darkText,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _darkText,
          fontFamily: 'Inter',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _darkSubText,
          fontFamily: 'Inter',
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _darkSubText,
          fontFamily: 'Inter',
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFF1F1F1),
        contentTextStyle: const TextStyle(color: Color(0xFF1A1C1C)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _darkSurface,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: _darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
        contentTextStyle: const TextStyle(
          color: _darkSubText,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: _darkText,
        iconColor: _darkSubText,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return inversePrimary;
          return _darkSubText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return inversePrimary.withValues(alpha: 0.3);
          }
          return _darkBorder;
        }),
      ),
    );
  }
}
