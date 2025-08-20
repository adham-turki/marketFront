import 'package:flutter/material.dart';

class AppColors {
  // Theme Colors
  static const Color primaryBackground =
      Colors.white; // Primary background color (white)
  static const Color secondaryBackground =
      Color(0xFFFFBD4D); // Secondary background color (orange)
  static const Color primaryText = Color(0xFFFF5C01); // Text color
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
  static const Color textPrimaryColor =
      Color(0xFFFF5C01); // Same as primaryText
  static const Color textSecondaryColor = Color(0xFF757575);
}
