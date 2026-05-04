import 'package:flutter/material.dart';

// Top-level notifier untuk toggle light/dark mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

/// SacredHub Color System — Deep Navy Blue + White + Black
/// Mengganti teal dengan biru gelap yang lebih premium dan modern
class AppTheme {
  // ─── Primary: Deep Navy Blue ──────────────────────────────────────────────
  static const Color primary = Color(0xFF1A237E);          // Deep Indigo
  static const Color primaryContainer = Color(0xFF283593); // Indigo 800
  static const Color primaryFixed = Color(0xFFBBDEFB);     // Blue 100
  static const Color primaryFixedDim = Color(0xFF90CAF9);  // Blue 200
  static const Color inversePrimary = Color(0xFF90CAF9);   // Blue 200
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFE3F2FD);
  static const Color onPrimaryFixed = Color(0xFF0D1B6E);

  // ─── Secondary: Amber/Gold ────────────────────────────────────────────────
  static const Color secondary = Color(0xFF875200);
  static const Color secondaryContainer = Color(0xFFF89C00); // Amber
  static const Color secondaryFixed = Color(0xFFFFDDBA);
  static const Color secondaryFixedDim = Color(0xFFFFB865);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF623A00);
  static const Color onSecondaryFixed = Color(0xFF2B1700);

  // ─── Tertiary: Electric Blue ──────────────────────────────────────────────
  static const Color tertiary = Color(0xFF0277BD);          // Light Blue 800
  static const Color tertiaryContainer = Color(0xFF0288D1); // Light Blue 700
  static const Color tertiaryFixed = Color(0xFFE1F5FE);
  static const Color tertiaryFixedDim = Color(0xFFB3E5FC);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFE1F5FE);
  static const Color onTertiaryFixed = Color(0xFF01579B);

  // ─── Error ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ─── Light Surface ────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF8F9FF);          // Slight blue tint
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFDDE1F0);
  static const Color surfaceVariant = Color(0xFFE4E7F5);
  static const Color surfaceContainer = Color(0xFFEEF0FA);
  static const Color surfaceContainerLow = Color(0xFFF3F5FC);
  static const Color surfaceContainerHigh = Color(0xFFE8EAF6);
  static const Color surfaceContainerHighest = Color(0xFFE3E6F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color inverseSurface = Color(0xFF1A1C2E);
  static const Color inverseOnSurface = Color(0xFFF0F1FF);

  static const Color onSurface = Color(0xFF0D0F1E);        // Near black with blue tint
  static const Color onSurfaceVariant = Color(0xFF2D3561);
  static const Color outline = Color(0xFF5C6494);
  static const Color outlineVariant = Color(0xFFBCC0E0);

  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF0D0F1E);

  // ─── Dark Mode — Deep Navy, tidak merusak mata ────────────────────────────
  static const Color _darkBg = Color(0xFF0A0D1A);          // Very dark navy
  static const Color _darkSurface = Color(0xFF141829);     // Dark navy surface
  static const Color _darkCard = Color(0xFF1C2038);        // Card background
  static const Color _darkText = Color(0xFFEEF0FF);        // Soft white-blue
  static const Color _darkSubText = Color(0xFF8B90B8);     // Muted blue-grey
  static const Color _darkBorder = Color(0xFF2A2F52);      // Subtle border
  static const Color _darkAccent = Color(0xFF90CAF9);      // Light blue accent

  // ─── Light Theme ─────────────────────────────────────────────────────────
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
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
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceContainerLowest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: onSurface),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onSurface),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: onSurfaceVariant),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: onSurfaceVariant),
      ),
      dividerTheme: const DividerThemeData(color: outlineVariant, thickness: 1, space: 1),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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

  // ─── Dark Theme — Deep Navy, nyaman di mata ───────────────────────────────
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: _darkAccent,
        onPrimary: const Color(0xFF0D1B6E),
        primaryContainer: const Color(0xFF1A237E),
        onPrimaryContainer: const Color(0xFFBBDEFB),
        secondary: secondaryFixedDim,
        onSecondary: onSecondaryFixed,
        secondaryContainer: const Color(0xFF663D00),
        onSecondaryContainer: secondaryFixed,
        tertiary: const Color(0xFF81D4FA),
        onTertiary: const Color(0xFF01579B),
        tertiaryContainer: const Color(0xFF0277BD),
        onTertiaryContainer: const Color(0xFFE1F5FE),
        error: const Color(0xFFFFB4AB),
        onError: const Color(0xFF690005),
        surface: _darkSurface,
        onSurface: _darkText,
        surfaceContainerHighest: _darkCard,
        outline: _darkSubText,
        outlineVariant: _darkBorder,
      ),
      scaffoldBackgroundColor: _darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _darkCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkAccent,
          foregroundColor: const Color(0xFF0D1B6E),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkAccent,
          side: BorderSide(color: _darkBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: _darkSubText),
        hintStyle: TextStyle(color: _darkSubText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _darkAccent,
        unselectedItemColor: _darkSubText,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: _darkText),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _darkText),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkText),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _darkText),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: _darkText),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _darkText),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _darkSubText),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _darkSubText),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkText,
        contentTextStyle: TextStyle(color: _darkBg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _darkCard,
        elevation: 0,
        titleTextStyle: TextStyle(color: _darkText, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: TextStyle(color: _darkSubText, fontSize: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _darkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(textColor: _darkText, iconColor: _darkSubText),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkAccent;
          return _darkSubText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkAccent.withValues(alpha: 0.3);
          return _darkBorder;
        }),
      ),
    );
  }

  // ─── Helper: dark mode color getters ─────────────────────────────────────
  static Color darkBg() => _darkBg;
  static Color darkSurface() => _darkSurface;
  static Color darkCard() => _darkCard;
  static Color darkText() => _darkText;
  static Color darkSubText() => _darkSubText;
  static Color darkBorder() => _darkBorder;
  static Color darkAccent() => _darkAccent;
}
