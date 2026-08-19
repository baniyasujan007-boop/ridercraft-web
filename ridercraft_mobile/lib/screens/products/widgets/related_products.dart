import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../widgets/section_header.dart';
import '../../home/widgets/product_card.dart';

/// Horizontal carousel of products in the same category as the one being
/// viewed. Built only from genuinely-loaded catalogue data — it is hidden when
/// the backend hasn't returned any matching products.
class RelatedProductsCarousel extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  const RelatedProductsCarousel({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'More Like This',
          kicker: 'You may also like',
          showDivider: false,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: ProductCard.slotHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
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