import 'package:flutter/material.dart';

class AppColors {
  // Theme Colors
  static const Color primaryBackground =
      Colors.white; // Primary background color (white)
  static const Color secondaryBackground =
      Color(0xFFFFBD4D); // Secondary background color (orange)
  static const Color primaryText =
      Color(0xFFFF5C01); // Primary brand color (orange)
  static const Color white =
      Colors.white; // White color (alias for convenience)

  // Additional theme variations
  static const Color lightBackground =
      Color(0xFFFFD280); // Lighter version of primary background
  static const Color darkText =
      Color(0xFFE64A00); // Darker version of primary text

  // Legacy colors (keeping for backward compatibility)
  static const Color primaryColor = Color(0xFFFF5C01); // Same as primaryText
  static const Color secondaryColor =
      Color(0xFFFFBD4D); // Same as secondaryBackground
  static const Color accentColor = Color(0xFFFF5C01); // Same as primaryText

  // Utility colors
  static const Color backgroundColor =
      Colors.white; // Same as primaryBackground
  static const Color surfaceColor = Colors.white; // Same as white
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFFFA000);

  // Text colors - ensuring visibility on all devices
  static const Color textPrimaryColor =
      Color(0xFF2C3E50); // Dark blue-gray for primary text
  static const Color textSecondaryColor =
      Color(0xFF7F8C8D); // Medium gray for secondary text
  static const Color textDarkColor =
      Color(0xFF2C3E50); // Dark color for important text
  static const Color textLightColor =
      Color(0xFF95A5A6); // Light color for less important text

  // Customer-specific colors - darker and closer to black
  static const Color customerTextPrimary =
      Color(0xFF1A1A1A); // Very dark, close to black
  static const Color customerTextSecondary = Color(0xFF2C2C2C); // Dark gray
  static const Color customerTextTertiary =
      Color(0xFF404040); // Medium dark gray

  // Admin-specific colors
  static const Color adminTextPrimary =
      Color(0xFF2C3E50); // Dark text for admin screens
  static const Color adminTextSecondary =
      Color(0xFF34495E); // Secondary dark text
  static const Color adminBorderColor = Color(0xFFBDC3C7); // Light border color
}
