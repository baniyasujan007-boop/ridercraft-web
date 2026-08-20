import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';

/// Gently pulsing placeholder blocks used while order/notification data loads.
/// A single repeating controller drives the opacity so skeletons never sit
/// blank on screen.
class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
      lowerBound: 0.35,
      upperBound: 0.85,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}

/// A single grey placeholder rectangle.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
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

/// Orders list skeleton: a header block and a few card-shaped placeholders.
class OrderListSkeleton extends StatelessWidget {
  const OrderListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => const _OrderCardSkeleton(),
      ),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 40, height: 40, radius: AppRadius.medium),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(width: 90, height: 12),
                  ],
                ),
              ),
              SkeletonBox(width: 72, height: 18),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              SkeletonBox(width: 96, height: 24, radius: AppRadius.pill),
              SizedBox(width: AppSpacing.sm),
              SkeletonBox(width: 120, height: 24, radius: AppRadius.pill),
            ],
          ),
        ],
      ),
    );
  }
}

/// Order detail skeleton: header, status timeline and totals placeholders.
class OrderDetailSkeleton extends StatelessWidget {
  const OrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          SkeletonBox(width: 220, height: 22),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 120, radius: AppRadius.large),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 96, radius: AppRadius.large),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 140, radius: AppRadius.large),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 120, radius: AppRadius.large),
        ],
      ),
    );
  }
}

/// Notification inbox skeleton: a header with the loading label plus a few
/// tile-shaped placeholders. The label keeps the loading state explicit so it
/// is never a blank screen.
class NotificationListSkeleton extends StatelessWidget {
  final int count;

  const NotificationListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        itemCount: count,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: AppColors.borderSubtle,
        ),
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg,
               vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 44, height: 44),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 180, height: 15),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(width: double.infinity, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}