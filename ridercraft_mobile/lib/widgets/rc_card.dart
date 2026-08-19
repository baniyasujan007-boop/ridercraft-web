import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'press_scale.dart';

/// Premium neutral surface card. Theme-agnostic: uses elevated-surface fill,
/// a thin border and a soft shadow — the default building block across the
/// RiderCraft redesign.
class RcCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? color;

  const RcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.large);
    final surface = color ?? AppColors.surfaceElevated;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadow.soft,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return PressScale(onTap: onTap, borderRadius: radius, child: card);
  }
}