import 'package:flutter/material.dart';

/// RiderCraft design tokens.
///
/// Mirrors the existing RiderCraft website frontend
/// (`client/src/features/shop/styles/landing-base.css`,
/// `client/src/features/product-details/styles/product-details.css`,
/// `client/src/features/auth/styles/premium-login-prototype.css`):
/// deep navy surfaces with a racing-orange accent.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFFFF6A00);
  static const Color primaryDark = Color(0xFFE65400);
  static const Color primaryLight = Color(0xFFFF7A1A);
  static const Color secondary = Color(0xFF94A3B8);
  static const Color accent = Color(0xFFF4B400);

  // Dark surface scale (website navy ramp)
  static const Color background = Color(0xFF07111D);
  static const Color surface = Color(0xFF0D1728);
  static const Color surfaceAlt = Color(0xFF111C2D);
  static const Color surfaceElevated = Color(0xFF1D2637);
  static const Color border = Color(0xFF283345);
  static const Color borderSubtle = Color(0xFF232E3C);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC9D2DF);
  static const Color textMuted = Color(0xFF8291A6);

  // Feedback
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFFB7185);
  static const Color warning = Color(0xFFFDE68A);
  static const Color info = Color(0xFF4AA3FF);

  // Light theme tokens (for completeness)
  static const Color lightBackground = Color(0xFFF4F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF17202D);
  static const Color lightTextSecondary = Color(0xFF8B95A5);

  // Brand gradients (website primary buttons)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6A00), Color(0xFFE65400)],
  );

  // Website hero/dark-page radial glow (orange, top-center)
  static const List<Color> heroGlowColors = [
    Color(0x33FF6A00),
    Color(0x00FF6A00),
  ];
}
