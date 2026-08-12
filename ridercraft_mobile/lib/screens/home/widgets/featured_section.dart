import 'package:flutter/material.dart';

import '../../../models/featured_section.dart';
import '../../../models/product.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/section_header.dart';
import 'product_card.dart';

/// A titled, horizontally scrollable row of featured products from
/// `GET /featured-sections`.
class FeaturedSectionView extends StatelessWidget {
  final FeaturedSection section;
  final ValueChanged<Product> onProductTap;
  final VoidCallback onSeeAll;

  const FeaturedSectionView({
    super.key,
    required this.section,
    required this.onProductTap,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: section.title,
          kicker: 'Featured',
          onSeeAll: onSeeAll,
        ),
        const SizedBox(height: 14),
        if (section.products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No products in this section right now.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 322,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: section.products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = section.products[index];
                return SizedBox(
                  width: 152,
                  child: ProductCard(
                    product: product,
                    onTap: () => onProductTap(product),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
