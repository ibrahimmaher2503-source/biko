import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme system for BikeRide application
/// Provides consistent colors, typography, spacing, and styling across
/// Customer App, Driver App, and Admin Panel
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // ==================== Color Definitions ====================

  /// HOW TO ADD CUSTOM SEMANTIC COLORS:
  ///
  /// 1. Define color constants here (following naming conventions):
  ///    static const Color success = Color(0xFF4CAF50);
  ///    static const Color warning = Color(0xFFFF9800);
  ///
  /// 2. Add to ColorScheme extensions in lightTheme/darkTheme:
  ///    colorScheme: ColorScheme.light(
  ///      primary: primary,
  ///      // Add custom colors using ColorScheme extensions or custom theme data
  ///    ),
  ///
  /// 3. Access in widgets:
  ///    final color = Theme.of(context).colorScheme.primary;
  ///
  /// 4. For app-specific colors not in Material ColorScheme:
  ///    - Define as static const Color here
  ///    - Access directly: AppTheme.customColor
  ///    - OR create ThemeExtension for better theme integration
  ///
  /// Example ThemeExtension:
  /// ```dart
  /// class CustomColors extends ThemeExtension<CustomColors> {
  ///   final Color success;
  ///   final Color warning;
  ///   // ...implementation
  /// }
  /// ```

  /// Primary brand color - BikeRide red
  static const Color primary = Color(0xFFE0062E);

  /// Primary dark variant
  static const Color primaryDark = Color(0xFFB00423);

  /// Background color for light mode
  static const Color backgroundLight = Color(0xFFF8F5F6);

  /// Background color for dark mode
  static const Color backgroundDark = Color(0xFF230F13);

  /// Neutral tint - light variant of primary for backgrounds
  static const Color neutralTint = Color(0xFFFCECEE);

  // ==================== Border Radius Values ====================

  /// Default border radius (8dp)
  static const double radiusDefault = 8.0;

  /// Large border radius (12dp)
  static const double radiusLarge = 12.0;

  /// Extra large border radius (16dp) - used for buttons and inputs
  static const double radiusXl = 16.0;

  /// Full/circular border radius
  static const double radiusFull = 9999.0;

  // ==================== Light Theme ====================

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: backgroundLight,
        surfaceTint: neutralTint,
        error: const Color(0xFFF44336),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF1C1B1F),
        onError: Colors.white,
      ),

      // Scaffold background
      scaffoldBackgroundColor: backgroundLight,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: const Color(0xFF1C1B1F),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C1B1F),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56), // 56dp height
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          elevation: 2,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

        // Border styles
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: Color(0xFFF44336)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
        ),

        // Label and hint styles
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF757575),
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF9E9E9E),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFF44336),
        ),
      ),

      // Text theme - English (Plus Jakarta Sans)
      textTheme: _buildEnglishTextTheme(),

      // Icon theme
      iconTheme: const IconThemeData(
        color: Color(0xFF1C1B1F),
        size: 24,
      ),
    );
  }

  // ==================== Dark Theme ====================

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primaryDark,
        surface: backgroundDark,
        surfaceTint: const Color(0xFF3E1F23),
        error: const Color(0xFFF44336),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFFE6E1E5),
        onError: Colors.black,
      ),

      // Scaffold background
      scaffoldBackgroundColor: backgroundDark,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: const Color(0xFFE6E1E5),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE6E1E5),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: const Color(0xFF2D1316),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          elevation: 2,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D1316),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

        // Border styles
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: Color(0xFF4A4458)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: Color(0xFF4A4458)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: Color(0xFFF44336)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
        ),

        // Label and hint styles
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFB0B0B0),
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF757575),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFF44336),
        ),
      ),

      // Text theme - English (Plus Jakarta Sans)
      textTheme: _buildEnglishTextTheme(forDarkMode: true),

      // Icon theme
      iconTheme: const IconThemeData(
        color: Color(0xFFE6E1E5),
        size: 24,
      ),
    );
  }

  // ==================== Text Theme Builders ====================

  /// Build English text theme using Plus Jakarta Sans
  static TextTheme _buildEnglishTextTheme({bool forDarkMode = false}) {
    final Color textColor = forDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1C1B1F);

    return GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        // Display styles
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 45,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),

        // Headline styles
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),

        // Title styles
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),

        // Body styles
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),

        // Label styles
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  /// Build Arabic text theme using Cairo font
  static TextTheme buildArabicTextTheme({bool forDarkMode = false}) {
    final Color textColor = forDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1C1B1F);

    return GoogleFonts.cairoTextTheme(
      TextTheme(
        // Display styles
        displayLarge: GoogleFonts.cairo(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        displayMedium: GoogleFonts.cairo(
          fontSize: 45,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        displaySmall: GoogleFonts.cairo(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),

        // Headline styles
        headlineLarge: GoogleFonts.cairo(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        headlineSmall: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),

        // Title styles
        titleLarge: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleMedium: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleSmall: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),

        // Body styles
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        bodySmall: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),

        // Label styles
        labelLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        labelMedium: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        labelSmall: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  /// Get theme data with Arabic font support
  static ThemeData getThemeWithLocale(Locale locale, {bool isDark = false}) {
    final baseTheme = isDark ? darkTheme : lightTheme;

    // For Arabic locale, use Cairo font
    if (locale.languageCode == 'ar') {
      return baseTheme.copyWith(
        textTheme: buildArabicTextTheme(forDarkMode: isDark),
      );
    }

    // For other locales, use Plus Jakarta Sans (default)
    return baseTheme;
  }
}
