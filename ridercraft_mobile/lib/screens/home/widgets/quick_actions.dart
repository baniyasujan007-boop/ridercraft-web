import 'package:flutter/material.dart';

import '../../../routes/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/press_scale.dart';

/// Quick action tiles on the Home screen: compact premium cards that jump to
/// the existing RiderCraft surfaces (Book Service, My Bike, Shop, My Bookings).
class QuickActions extends StatelessWidget {
  final void Function(int index) onNavigateTab;

  const QuickActions({super.key, required this.onNavigateTab});

  void _open(BuildContext context, int tabIndex) {
    onNavigateTab(tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(
        label: 'Book Service',
        icon: Icons.build_rounded,
        onTap: () => _open(context, 1),
      ),
      _Action(
        label: 'My Bike',
        icon: Icons.sports_motorsports_rounded,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.myBikes),
      ),
      _Action(
        label: 'Shop',
        icon: Icons.shopping_bag_rounded,
        onTap: () => _open(context, 2),
      ),
      _Action(
        label: 'My Bookings',
        icon: Icons.calendar_month_rounded,
        onTap: () => _open(context, 3),
      ),
    ];

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final tileHeight = (60 * textScale).clamp(60.0, 108.0);
    final tileWidth = (MediaQuery.sizeOf(context).width - 32 - 12) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: tileWidth / tileHeight,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) => actions[index],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _Action({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(icon, color: AppColors.primaryLight, size: 21),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}