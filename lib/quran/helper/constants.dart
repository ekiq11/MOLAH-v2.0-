// utils/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF059669);
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryLight = Color.fromARGB(218, 39, 39, 39);

  // Secondary colors
  static const Color secondaryDark = Color.fromARGB(255, 212, 67, 0);
  static const Color secondary = Color.fromARGB(255, 255, 121, 43);

  // Purple for Dzikir
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleDark = Color.fromARGB(255, 114, 41, 241);

  // Neutral colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color background = Color(0xFFF9FAFB);
  static const Color cardBackground = Colors.white;
  static const Color border = Color(0xFFE5E7EB);

  // Gradient colors
  static const List<Color> primaryGradient = [primary, primaryDark];
  static const List<Color> secondaryGradient = [secondary, secondaryDark];
  static const List<Color> purpleGradient = [purple, purpleDark];
  static const List<Color> headerGradient = [
    Color.fromARGB(255, 87, 87, 87),
    Color.fromARGB(218, 49, 49, 49),
  ];
}

class AppTextStyles {
  // Headers
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  // Body text
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );

  // Special text styles
  static const TextStyle prayerName = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle prayerTime = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
}

class AppDimensions {
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Card heights
  static const double cardHeightSmall = 100.0;
  static const double cardHeightMedium = 140.0;
  static const double cardHeightLarge = 200.0;
}

class AppAnimations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration long = Duration(milliseconds: 600);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
}

class AppAssets {
  static const String iconQuran = 'assets/other/iconquran.png';
  static const String iconLauncher = '@mipmap/ic_launcher';
}
