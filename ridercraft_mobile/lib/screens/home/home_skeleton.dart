import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../theme/app_colors.dart';

const Color _base = AppColors.surface;
const Color _highlight = AppColors.surfaceElevated;

/// Polished skeleton shown while the Home screen first loads. Never a blank
/// screen.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base,
      highlightColor: _highlight,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: const [
          _HeroSkeleton(),
          SizedBox(height: 20),
          _GridSkeleton(),
          SizedBox(height: 28),
          _SectionHeaderSkeleton(),
          SizedBox(height: 12),
          _ProductRowSkeleton(),
          SizedBox(height: 28),
          _SectionHeaderSkeleton(),
          SizedBox(height: 12),
          _ProductRowSkeleton(),
          SizedBox(height: 28),
          _PromoSkeleton(),
        ],
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _base,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          2,
          (_) => Expanded(
            child: Container(
              height: 58,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _base,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  const _SectionHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 20,
        width: 160,
        decoration: BoxDecoration(
          color: _base,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _ProductRowSkeleton extends StatelessWidget {
  const _ProductRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
        borderRadius: BorderRadius.circular(16),
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
              children: [
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: _base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: _base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _base,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
