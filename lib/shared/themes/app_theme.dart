import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF6750A4);
  // Unused color variants - keeping for future use
  // ignore: unused_field
  static const Color _primaryVariant = Color(0xFF7F67BE);
  static const Color _secondary = Color(0xFF625B71);
  static const Color _surface = Color(0xFFFFFBFE);
  static const Color _surfaceVariant = Color(0xFFE7E0EC);
  // Background colors - kept for future use
  // ignore: unused_field
  static const Color _background = Color(0xFFFFFBFE);
  static const Color _error = Color(0xFFBA1A1A);
  static const Color _onPrimary = Color(0xFFFFFFFF);
  static const Color _onSecondary = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF1C1B1F);
  // ignore: unused_field
  static const Color _onBackground = Color(0xFF1C1B1F);
  static const Color _onError = Color(0xFFFFFFFF);

  // Dark theme colors
  static const Color _primaryDark = Color(0xFFD0BCFF);
  // Unused color variants - keeping for future use  
  // ignore: unused_field
  static const Color _primaryVariantDark = Color(0xFF6750A4);
  static const Color _secondaryDark = Color(0xFFCCC2DC);
  static const Color _surfaceDark = Color(0xFF1C1B1F);
  static const Color _surfaceVariantDark = Color(0xFF49454F);
  // ignore: unused_field
  static const Color _backgroundDark = Color(0xFF1C1B1F);
  static const Color _errorDark = Color(0xFFFFB4AB);
  static const Color _onPrimaryDark = Color(0xFF381E72);
  static const Color _onSecondaryDark = Color(0xFF332D41);
  static const Color _onSurfaceDark = Color(0xFFE6E1E5);
  // ignore: unused_field
  static const Color _onBackgroundDark = Color(0xFFE6E1E5);
  static const Color _onErrorDark = Color(0xFF690005);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primaryColor,
        secondary: _secondary,
        surface: _surface,
        surfaceContainer: _surfaceVariant,
        error: _error,
        onPrimary: _onPrimary,
        onSecondary: _onSecondary,
        onSurface: _onSurface,
        onError: _onError,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        foregroundColor: _onSurface,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: _onSurface,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: _surface,
        surfaceTintColor: _primaryColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surface,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _onSurface,
        type: BottomNavigationBarType.fixed,
        elevation: 3,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: _onPrimary,
        elevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _onPrimary,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error, width: 1),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      
      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: _onBackground,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: _onBackground,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: _onBackground,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: _onBackground,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: _onBackground,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: _onBackground,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: _onBackground,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _onBackground,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _onBackground,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _onBackground,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _onBackground,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _onBackground,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _onBackground,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _onBackground,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _onBackground,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryDark,
        secondary: _secondaryDark,
        surface: _surfaceDark,
        surfaceContainer: _surfaceVariantDark,
        error: _errorDark,
        onPrimary: _onPrimaryDark,
        onSecondary: _onSecondaryDark,
        onSurface: _onSurfaceDark,
        onError: _onErrorDark,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceDark,
        foregroundColor: _onSurfaceDark,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: _onSurfaceDark,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: _surfaceDark,
        surfaceTintColor: _primaryDark,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceDark,
        selectedItemColor: _primaryDark,
        unselectedItemColor: _onSurfaceDark,
        type: BottomNavigationBarType.fixed,
        elevation: 3,
      ),
      
      // Similar theme configurations for dark mode...
      // (keeping it concise for brevity)
    );
  }
}
