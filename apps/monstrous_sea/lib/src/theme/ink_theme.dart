import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monstrous_core/monstrous_core.dart';

/// Design tokens and typography defining the 18th-century nautical cartography aesthetic.
class InkTheme {
  const InkTheme._();

  // Parchment Background & Surface Tones
  static const Color parchmentBackground = Color(0xFFF4EBD9);
  static const Color parchmentSurface = Color(0xFFEADEC7);
  static const Color parchmentDark = Color(0xFFD5C4A1);
  static const Color parchmentHighlight = Color(0xFFFAF6EE);
  static const Color parchmentBorder = Color(0xFFBCAAA4);

  // Iron-Gall & Sepia Ink Tones
  static const Color inkPrimary = Color(0xFF1B1612);
  static const Color inkSecondary = Color(0xFF3D332A);
  static const Color inkMuted = Color(0xFF706253);
  static const Color inkFaint = Color(0xFFA89984);

  // Maritime Accents
  static const Color crimsonAccent = Color(0xFF8B1E1E); // Danger, Blood, Vitality loss
  static const Color goldAccent = Color(0xFFB58900);    // Doubloons, Relics, Victory
  static const Color abyssNavy = Color(0xFF1A2F3B);     // Deep Trench, Night Sea
  static const Color verdigrisGreen = Color(0xFF2A5A48);// Venom, Ghostly sails

  // Rarity Colors
  static Color rarityColor(RarityLevel rarity) => switch (rarity) {
        RarityLevel.common => inkSecondary,
        RarityLevel.rare => const Color(0xFF1C4E80),
        RarityLevel.epic => const Color(0xFF6C3483),
        RarityLevel.legendary => goldAccent,
      };

  // Typography
  static TextStyle get titleLarge => GoogleFonts.pirataOne(
        fontSize: 32,
        fontWeight: FontWeight.normal,
        color: inkPrimary,
        letterSpacing: 1.2,
      );

  static TextStyle get titleMedium => GoogleFonts.pirataOne(
        fontSize: 24,
        fontWeight: FontWeight.normal,
        color: inkPrimary,
        letterSpacing: 1.0,
      );

  static TextStyle get subtitle => GoogleFonts.imFellEnglish(
        fontSize: 18,
        fontStyle: FontStyle.italic,
        color: inkSecondary,
      );

  static TextStyle get body => GoogleFonts.imFellEnglish(
        fontSize: 16,
        color: inkPrimary,
        height: 1.35,
      );

  static TextStyle get bodyBold => GoogleFonts.imFellEnglish(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: inkPrimary,
      );

  static TextStyle get caption => GoogleFonts.imFellEnglish(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: inkMuted,
      );

  static TextStyle get statLabel => GoogleFonts.cinzel(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: inkSecondary,
        letterSpacing: 0.8,
      );

  static TextStyle get statValue => GoogleFonts.cinzel(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: inkPrimary,
      );

  // Complete Material ThemeData
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: parchmentBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: inkPrimary,
        onPrimary: parchmentHighlight,
        secondary: goldAccent,
        onSecondary: inkPrimary,
        error: crimsonAccent,
        onError: parchmentHighlight,
        surface: parchmentSurface,
        onSurface: inkPrimary,
      ),
      textTheme: TextTheme(
        headlineLarge: titleLarge,
        headlineMedium: titleMedium,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: parchmentSurface,
          foregroundColor: inkPrimary,
          elevation: 2,
          side: const BorderSide(color: inkPrimary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.pirataOne(fontSize: 20, letterSpacing: 1.0),
        ),
      ),
      cardTheme: CardThemeData(
        color: parchmentSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: inkMuted, width: 1.2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: inkMuted,
        thickness: 1,
        space: 20,
      ),
    );
  }
}
