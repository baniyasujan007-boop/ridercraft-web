import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_button.dart';

/// Premium empty-orders state with a soft entrance, a compact illustration
/// built from existing icons and the primary "Explore Shop" action.
class EmptyOrders extends StatelessWidget {
  /// Called when the user taps "Explore Shop".
  final VoidCallback onExploreShop;

  const EmptyOrders({super.key, required this.onExploreShop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Layered "parcel on the road" illustration from brand icons.
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 20,
                    bottom: 24,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 42,
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 24,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 42,
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primaryLight,
                      size: 42,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'No orders yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Your next ride essential starts here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            RcButton(
              label: 'EXPLORE SHOP',
              icon: Icons.storefront_rounded,
              onPressed: onExploreShop,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}