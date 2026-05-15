import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF00BC7D);
  static const Color secondaryGreen = Color(0xFF009689);
  static const Color tertiaryBlue = Color(0xFF007595);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);

  // Gradient
  static const LinearGradient mainGradient = LinearGradient(
    colors: [primaryGreen, secondaryGreen, tertiaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
