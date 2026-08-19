import 'package:flutter/material.dart';

/// RiderCraft design tokens — dark premium motorcycle aesthetic.
///
/// Foundation: near-black neutral surfaces with a high-contrast RiderCraft
/// Red reserved for primary CTAs, selected navigation, price emphasis,
/// brand moments and small gradients. Neutral surfaces carry the rest of the
/// UI so the accent stays loud and never feels "everywhere".
abstract final class AppColors {
  // Brand — RiderCraft Red
  static const Color primary = Color(0xFFE31B23);
  static const Color primaryDark = Color(0xFFC4151D);
  static const Color primaryLight = Color(0xFFFF464D);
  static const Color accentRed = Color(0xFFFF2B32);
  static const Color secondary = Color(0xFFA7ADB7);
  static const Color accent = Color(0xFFF4B400);

  // Dark neutral surface ramp
  static const Color background = Color(0xFF08090B);
  static const Color surface = Color(0xFF111317);
  static const Color surfaceAlt = Color(0xFF171A1F);
  static const Color surfaceElevated = Color(0xFF1D2127);
  static const Color border = Color(0xFF262B32);
  static const Color borderSubtle = Color(0xFF1B1F25);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA7ADB7);
  static const Color textMuted = Color(0xFF6F7682);

  // Feedback
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF4AA3FF);

  // Light theme tokens (for completeness)
  static const Color lightBackground = Color(0xFFF4F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF17202D);
  static const Color lightTextSecondary = Color(0xFF8B95A5);

  // Brand gradients — RiderCraft Red CTA
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE31B23), Color(0xFFFF2B32)],
  );

  /// Red radial glow used on dark hero surfaces.
  static const List<Color> heroGlowColors = [
    Color(0x30E31B23),
    Color(0x00E31B23),
  ];
}