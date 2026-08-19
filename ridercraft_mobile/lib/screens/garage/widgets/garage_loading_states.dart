import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_skeleton.dart';

/// Shimmer skeleton for the garage dashboard (header + summary + card rows).
class GarageDashboardSkeleton extends StatelessWidget {
  const GarageDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return RcSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Header block
          const RcSkeletonBox(height: 150, radius: AppRadius.hero),
          const SizedBox(height: AppSpacing.lg),
          // Summary row
          const Row(
            children: [
              Expanded(child: RcSkeletonBox(height: 96)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: RcSkeletonBox(height: 96)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: RcSkeletonBox(height: 96)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          const RcSkeletonBox(width: 160, height: 16),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < 3; i++) ...[
            const RcSkeletonBox(height: 118, radius: AppRadius.large),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

/// Shimmer skeleton for the garage bookings list.
class GarageBookingsSkeleton extends StatelessWidget {
  const GarageBookingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return RcSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (var i = 0; i < 4; i++) ...[
            const RcSkeletonBox(height: 118, radius: AppRadius.large),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}