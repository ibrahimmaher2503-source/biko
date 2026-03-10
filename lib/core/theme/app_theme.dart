import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic color extension for surfaces, borders, and status states.
///
/// Access via: `Theme.of(context).extension<AppColorsExtension>()!`
///
/// Automatically adapts to light/dark mode when registered on both themes.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.surfaceElevated,
    required this.surfaceContainer,
    required this.border,
    required this.borderSubtle,
    required this.textMuted,
    required this.info,
    required this.infoBg,
    required this.infoBorder,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
  });

  /// Card backgrounds, elevated containers
  final Color surfaceElevated;

  /// Input field backgrounds, secondary containers
  final Color surfaceContainer;

  /// Default border color for cards, inputs
  final Color border;

  /// Subtle/light border for dividers
  final Color borderSubtle;

  /// Secondary/muted text
  final Color textMuted;

  /// Info icon/text foreground
  final Color info;

  /// Info tip background
  final Color infoBg;

  /// Info tip border
  final Color infoBorder;

  /// Success icon/text foreground
  final Color success;

  /// Success status background
  final Color successBg;

  /// Warning icon/text foreground
  final Color warning;

  /// Warning status background
  final Color warningBg;

  @override
  AppColorsExtension copyWith({
    Color? surfaceElevated,
    Color? surfaceContainer,
    Color? border,
    Color? borderSubtle,
    Color? textMuted,
    Color? info,
    Color? infoBg,
    Color? infoBorder,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
  }) {
    return AppColorsExtension(
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textMuted: textMuted ?? this.textMuted,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
      infoBorder: infoBorder ?? this.infoBorder,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceContainer:
          Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
    );
  }
}

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

  /// Orange accent — used for Package Delivery card icon
  static const Color orange = Color(0xFFF97316);

  /// Orange background tint (light)
  static const Color orangeBgLight = Color(0xFFFFF7ED);

  /// Orange background tint (dark)
  static const Color orangeBgDark = Color(0xFF7C2D12);

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
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: backgroundLight,
        surfaceTint: neutralTint,
        error: Color(0xFFF44336),
        onSecondary: Colors.white,
        onSurface: Color(0xFF1C1B1F),
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
          side: const BorderSide(color: primary),
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

      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Text theme - English (Plus Jakarta Sans)
      textTheme: _buildEnglishTextTheme(),

      // Icon theme
      iconTheme: const IconThemeData(
        color: Color(0xFF1C1B1F),
        size: 24,
      ),

      // Theme extensions
      extensions: const <ThemeExtension<dynamic>>[
        AppColorsExtension(
          surfaceElevated: Colors.white,
          surfaceContainer: Color(0xFFF1F5F9),
          border: Color(0xFFE2E8F0),
          borderSubtle: Color(0xFFF1F5F9),
          textMuted: Color(0xFF64748B),
          info: Color(0xFF2563EB),
          infoBg: Color(0xFFEFF6FF),
          infoBorder: Color(0xFFDBEAFE),
          success: Color(0xFF16A34A),
          successBg: Color(0xFFDCFCE7),
          warning: Color(0xFFD97706),
          warningBg: Color(0xFFFEF3C7),
        ),
      ],
    );
  }

  // ==================== Dark Theme ====================

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryDark,
        surface: backgroundDark,
        surfaceTint: Color(0xFF3E1F23),
        error: Color(0xFFF44336),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFE6E1E5),
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
          side: const BorderSide(color: primary),
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

      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Text theme - English (Plus Jakarta Sans)
      textTheme: _buildEnglishTextTheme(forDarkMode: true),

      // Icon theme
      iconTheme: const IconThemeData(
        color: Color(0xFFE6E1E5),
        size: 24,
      ),

      // Theme extensions
      extensions: const <ThemeExtension<dynamic>>[
        AppColorsExtension(
          surfaceElevated: Color(0xFF2D1316),
          surfaceContainer: Color(0xFF1E293B),
          border: Color(0xFF334155),
          borderSubtle: Color(0xFF1E293B),
          textMuted: Color(0xFF94A3B8),
          info: Color(0xFF60A5FA),
          infoBg: Color(0xFF1E3A5F),
          infoBorder: Color(0xFF2563EB),
          success: Color(0xFF4ADE80),
          successBg: Color(0xFF14532D),
          warning: Color(0xFFFBBF24),
          warningBg: Color(0xFF78350F),
        ),
      ],
    );
  }

  // ==================== Text Theme Builders ====================

  /// Build English text theme using Plus Jakarta Sans
  static TextTheme _buildEnglishTextTheme({bool forDarkMode = false}) {
    final textColor = forDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1C1B1F);

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
    final textColor = forDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1C1B1F);

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
