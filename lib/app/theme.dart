import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Footprint Guard design tokens.
/// Ultra-premium Amoled: absolute black (#000000), liquid-glass surfaces,
/// hairline glossy borders, and restrained status glows only:
/// emerald #00FFA3 (safe) and crimson #FF3B30 (critical).
class FGColors {
  static const Color black = Color(0xFF000000);
  static const Color glassFill = Color(0x14FFFFFF); // ~8% white
  static const Color glassFillStrong = Color(0x1FFFFFFF);
  static const Color glassBorder = Color(0x2EFFFFFF); // ~18% white hairline
  static const Color glassBorderSoft = Color(0x1AFFFFFF);
  static const Color textHi = Color(0xFFF5F7FA);
  static const Color textMid = Color(0xFFA7B0BE);
  static const Color textLow = Color(0xFF6B7686);
  static const Color emerald = Color(0xFF00FFA3);
  static const Color emeraldDim = Color(0xFF00C97E);
  static const Color amber = Color(0xFFFFC24B);
  static const Color orangeDeep = Color(0xFFFF8A3D);
  static const Color crimson = Color(0xFFFF3B30);

  static Color tierColorName(String tier) {
    switch (tier) {
      case 'safe':
        return emerald;
      case 'low':
        return const Color(0xFF7BE8B8);
      case 'moderate':
        return amber;
      case 'critical':
        return crimson;
      default:
        return textMid;
    }
  }
}

class FGTheme {
  /// Cairo for Arabic, Inter for Latin — light/medium weights.
  static ThemeData dark({required bool arabic}) {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FGColors.black,
      canvasColor: FGColors.black,
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF0A0B0E),
        primary: FGColors.emerald,
        secondary: FGColors.textMid,
        error: FGColors.crimson,
        onSurface: FGColors.textHi,
        onPrimary: Colors.black,
      ),
      dividerColor: FGColors.glassBorderSoft,
      splashColor: const Color(0x14FFFFFF),
      highlightColor: const Color(0x0DFFFFFF),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? FGColors.emerald
              : FGColors.textMid,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? const Color(0x3300FFA3)
              : const Color(0x26FFFFFF),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: FGColors.emerald),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF14161B),
        contentTextStyle: TextStyle(color: FGColors.textHi),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: FGColors.emerald,
        selectionColor: Color(0x3300FFA3),
        selectionHandleColor: FGColors.emerald,
      ),
    );
    final textTheme = arabic
        ? GoogleFonts.cairoTextTheme(base.textTheme)
        : GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: textTheme.apply(
        bodyColor: FGColors.textHi,
        displayColor: FGColors.textHi,
      ),
    );
  }
}

/// Thin, precise text styles used across the premium UI.
class FGTxt {
  static const TextStyle eyebrow = TextStyle(
    fontSize: 10.5,
    letterSpacing: 2.2,
    fontWeight: FontWeight.w600,
    color: FGColors.textLow,
  );
  static const TextStyle h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w300,
    color: FGColors.textHi,
    height: 1.15,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w500,
    color: FGColors.textHi,
  );
  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: FGColors.textMid,
    height: 1.5,
  );
  static const TextStyle small = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: FGColors.textLow,
    height: 1.45,
  );
  static const TextStyle mono = TextStyle(
    fontSize: 12,
    fontFamily: 'monospace',
    color: FGColors.textMid,
    height: 1.5,
  );
}
