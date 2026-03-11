import 'package:flutter/material.dart';

/// App-wide color constants matching the web app's dark Tailwind theme.
class AppColors {
  AppColors._();

  // Base grays (Tailwind gray-*)
  static const Color bg = Color(0xFF111827); // gray-900
  static const Color surface = Color(0xFF1F2937); // gray-800
  static const Color surfaceHover = Color(0xFF374151); // gray-700
  static const Color border = Color(0xFF374151); // gray-700
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFD1D5DB); // gray-300
  static const Color textMuted = Color(0xFF9CA3AF); // gray-400
  static const Color textDim = Color(0xFF6B7280); // gray-500

  // Accent / brand
  static const Color purple400 = Color(0xFFA78BFA);
  static const Color purple500 = Color(0xFF8B5CF6);
  static const Color purple600 = Color(0xFF7C3AED);
  static const Color pink500 = Color(0xFFEC4899);
  static const Color pink600 = Color(0xFFDB2777);

  // Semantic
  static const Color error = Color(0xFF7F1D1D); // red-900 bg
  static const Color errorBorder = Color(0xFF991B1B); // red-700
  static const Color errorText = Color(0xFFFECACA); // red-200
  static const Color success = Color(0xFF34D399); // green-400
  static const Color warning = Color(0xFFFBBF24); // yellow-400

  // Panel accent colors (matching web icons)
  static const Color teal300 = Color(0xFF5EEAD4);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color yellow300 = Color(0xFFFDE047);
  static const Color indigo300 = Color(0xFFA5B4FC);
  static const Color teal500 = Color(0xFF14B8A6);

  // Gradients
  static const LinearGradient purplePinkGradient = LinearGradient(
    colors: [purple600, pink600],
  );
  static const LinearGradient blueIndigoGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
  );
  static const LinearGradient greenTealGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF14B8A6)],
  );
}

/// Build the dark Material theme for the app.
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple500,
      secondary: AppColors.pink500,
      surface: AppColors.surface,
      error: AppColors.errorText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppColors.textSecondary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.purple500, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textDim),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textSecondary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textMuted),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
