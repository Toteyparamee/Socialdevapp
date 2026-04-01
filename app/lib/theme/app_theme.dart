import 'package:flutter/material.dart';

class AppTheme {
  // Gradient colors
  static const Color gradientStart = Color(0xFF4A90D9);
  static const Color gradientEnd = Color(0xFFA78BFA);

  // Primary
  static const Color primary = Color(0xFF4A90D9);
  static const Color primaryDark = Color(0xFF3B7DD8);
  static const Color accent = Color(0xFFA78BFA);

  // Marker colors
  static const Color markerUser = Color(0xFFEF4444);
  static const Color markerGov = Color(0xFF3B82F6);
  static const Color markerUrgent = Color(0xFFF97316);

  // Status colors
  static const Color statusPending = Color(0xFFFBBF24);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusResolved = Color(0xFF10B981);

  // Neutrals
  static const Color bg = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFF1F5F9);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF4A90D9), Color(0xFF7C5CE0)],
  );

  static final BorderRadius radiusSm = BorderRadius.circular(8);
  static final BorderRadius radiusMd = BorderRadius.circular(12);
  static final BorderRadius radiusLg = BorderRadius.circular(16);
  static final BorderRadius radiusXl = BorderRadius.circular(24);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primary,
        fontFamily: 'NotoSansThai',
        scaffoldBackgroundColor: bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: textPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputBg,
          border: OutlineInputBorder(
            borderRadius: radiusMd,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radiusMd,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radiusMd,
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radiusMd,
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: radiusMd),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}
