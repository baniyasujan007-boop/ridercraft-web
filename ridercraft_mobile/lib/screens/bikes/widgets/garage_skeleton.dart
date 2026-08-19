import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_skeleton.dart';

/// Premium shimmer skeleton for the garage dashboard so loading never shows a
/// blank page. Mirrors the header, selector and hero card layout.
class GarageSkeleton extends StatelessWidget {
  const GarageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RcSkeleton(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const RcSkeletonBox(width: 110, height: 11, radius: 4),
                const SizedBox(height: AppSpacing.sm),
                const RcSkeletonBox(width: 180, height: 26, radius: 6),
                const SizedBox(height: AppSpacing.xxl),
                const SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      RcSkeletonBox(width: 96, height: 36, radius: 18),
                      SizedBox(width: AppSpacing.sm),
                      RcSkeletonBox(width: 96, height: 36, radius: 18),
                      SizedBox(width: AppSpacing.sm),
                      RcSkeletonBox(width: 72, height: 36, radius: 18),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                RcSkeletonBox(height: 180, radius: AppRadius.hero),
                const SizedBox(height: AppSpacing.md),
                RcSkeletonBox(height: 150, radius: AppRadius.hero),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: const Text(
            'Loading bikes…',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
