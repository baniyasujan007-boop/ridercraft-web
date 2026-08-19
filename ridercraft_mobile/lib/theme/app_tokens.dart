import 'package:flutter/material.dart';

/// RiderCraft spacing scale. Use these values instead of ad-hoc paddings so
/// the layout stays coherent across screens: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 48;
}

/// RiderCraft surface radii.
abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double hero = 24;
  static const double pill = 999;
}

/// Subtle, modern elevation shadows — surface contrast + thin borders carry
/// most of the depth; shadows are kept soft.
abstract final class AppShadow {
  /// Default elevated surface shadow.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// Floating card / hero shadow.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  /// Glow underneath primary CTAs.
  static const List<BoxShadow> redGlow = [
    BoxShadow(
      color: Color(0x33E31B23),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}