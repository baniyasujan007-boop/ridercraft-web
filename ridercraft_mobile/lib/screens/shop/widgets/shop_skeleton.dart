import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_skeleton.dart';
import '../../home/widgets/product_card.dart';

/// Shop loading state: shimmer for the search field, category rail, toolbar
/// and a grid of product-card-shaped blocks so the layout doesn't jump when
/// the real catalogue arrives.
class ShopSkeleton extends StatelessWidget {
  const ShopSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return RcSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const RcSkeletonBox(height: 52, radius: AppRadius.large),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                const RcSkeletonBox(
                  width: 84,
                  height: 32,
                  radius: AppRadius.pill,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              RcSkeletonBox(width: 92, height: 36, radius: AppRadius.pill),
              SizedBox(width: 8),
              RcSkeletonBox(width: 132, height: 36, radius: AppRadius.pill),
              Spacer(),
              RcSkeletonBox(width: 46, height: 14, radius: 7),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = (constraints.maxWidth / 190)
                  .floor()
                  .clamp(2, 6)
                  .toInt();
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  mainAxisExtent: ProductCard.slotHeight(context),
                ),
                itemCount: 6,
                itemBuilder: (context, index) => const _CardBlock(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  const _CardBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          RcSkeletonBox(height: 168),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RcSkeletonBox(width: 64, height: 10, radius: 5),
                SizedBox(height: 8),
                RcSkeletonBox(height: 12, radius: 6),
                SizedBox(height: 6),
                RcSkeletonBox(width: 140, height: 12, radius: 6),
                SizedBox(height: 12),
                RcSkeletonBox(width: 90, height: 16, radius: 8),
                SizedBox(height: 12),
                RcSkeletonBox(height: 34, radius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}