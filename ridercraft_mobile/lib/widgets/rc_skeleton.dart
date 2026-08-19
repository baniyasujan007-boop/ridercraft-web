import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Shimmer wrapper used by skeleton loading layouts. Single source for the
/// brand shimmer so every loading screen stays consistent.
class RcSkeleton extends StatelessWidget {
  final Widget child;

  const RcSkeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceAlt,
      highlightColor: AppColors.surfaceElevated,
      child: child,
    );
  }
}

/// A single shimmer block that mirrors a future filled surface.
class RcSkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const RcSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}