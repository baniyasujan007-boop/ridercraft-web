import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import 'widgets/product_card.dart';

const Color _base = AppColors.surface;
const Color _highlight = AppColors.surfaceElevated;

/// Polished skeleton shown while the Home screen first loads. Mirrors the
/// redesigned layout — greeting, search, garage, hero, quick actions,
/// featured rows, services — so the screen never appears blank.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base,
      highlightColor: _highlight,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: const [
          _GreetingSkeleton(),
          SizedBox(height: AppSpacing.md),
          _SearchSkeleton(),
          SizedBox(height: AppSpacing.xl),
          _HeroSkeleton(),
          SizedBox(height: AppSpacing.xl),
          _QuickActionsSkeleton(),
          SizedBox(height: AppSpacing.xl),
          _SectionHeaderSkeleton(),
          SizedBox(height: 12),
          _ProductRowSkeleton(),
          SizedBox(height: AppSpacing.xl),
          _SectionHeaderSkeleton(),
          SizedBox(height: 12),
          _ServiceRowsSkeleton(),
          SizedBox(height: AppSpacing.xl),
          _PromoSkeleton(),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const _Block({
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: _base, borderRadius: borderRadius),
    );
  }
}

class _GreetingSkeleton extends StatelessWidget {
  const _GreetingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Block(height: 10, width: 92),
          SizedBox(height: AppSpacing.sm),
          _Block(height: 26, width: 210),
        ],
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: const _Block(
        height: 52,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.75);
    final height = ((width - 32) * 0.62 * textScale).clamp(170.0, 400.0);
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: _base,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
    );
  }
}

class _QuickActionsSkeleton extends StatelessWidget {
  const _QuickActionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < 2; i++) ...[
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: _base,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
              ),
            ),
            if (i == 0) const SizedBox(width: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  const _SectionHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Block(height: 10, width: 84),
          SizedBox(height: AppSpacing.xs),
          _Block(height: 20, width: 160),
        ],
      ),
    );
  }
}

class _ProductRowSkeleton extends StatelessWidget {
  const _ProductRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final rowHeight = ProductCard.slotHeight(context);
    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const _ProductCardSkeleton(),
      ),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      decoration: BoxDecoration(
        color: _base,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 152,
            width: double.infinity,
            child: DecoratedBox(decoration: BoxDecoration(color: _highlight)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Block(height: 12, width: 120),
                SizedBox(height: 8),
                _Block(height: 12, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRowsSkeleton extends StatelessWidget {
  const _ServiceRowsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: const [
          _Block(
            height: 66,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
          ),
          SizedBox(height: AppSpacing.sm),
          _Block(
            height: 66,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
          ),
          SizedBox(height: AppSpacing.sm),
          _Block(
            height: 66,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
          ),
        ],
      ),
    );
  }
}

class _PromoSkeleton extends StatelessWidget {
  const _PromoSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: _base,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
    );
  }
}
