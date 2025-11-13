import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

class TaskyTheme {
  static ThemeData light({Color? accentColor}) {
    final primary = accentColor ?? TaskyPalette.mint;
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: TaskyPalette.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: TaskyPalette.lavender,
        tertiary: TaskyPalette.blush,
        surface: Colors.white,
        onSurface: TaskyPalette.midnight,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: TaskyPalette.midnight,
        displayColor: TaskyPalette.midnight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: TaskyPalette.cream,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: TaskyPalette.midnight,
        ),
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TaskyPalette.lavender,
        foregroundColor: TaskyPalette.midnight,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: TaskyPalette.lavender.withOpacity(0.25),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: TaskyPalette.midnight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TaskyPalette.cream,
        indicatorColor: TaskyPalette.lavender.withOpacity(0.4),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: TaskyPalette.midnight,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? TaskyPalette.midnight
                : TaskyPalette.midnight.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  static ThemeData dark({Color? accentColor}) {
    final primary = accentColor ?? TaskyPalette.mint;
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF1a1a2e),
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: TaskyPalette.aqua,
        tertiary: TaskyPalette.coral,
        surface: const Color(0xFF16213e),
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1a1a2e),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TaskyPalette.mint,
        foregroundColor: Colors.white,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: TaskyPalette.mint.withOpacity(0.2),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF16213e),
        indicatorColor: TaskyPalette.mint.withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? TaskyPalette.mint
                : Colors.white.withOpacity(0.6),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? TaskyPalette.mint
                : Colors.white.withOpacity(0.6),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF16213e),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: Colors.white.withOpacity(0.1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TaskyPalette.mint, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TaskyPalette.mint,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TaskyPalette.mint,
        ),
      ),
    );
  }
}
