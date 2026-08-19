import 'package:flutter/material.dart';

import '../../../models/bike.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_button.dart';
import '../../../widgets/rc_image.dart';

/// The signature Garage card: a large motorcycle visual with the rider's
/// active bike, its name/specs and the existing garage actions.
///
/// Uses only data the local Bike model actually stores (brand, model, year,
/// engine capacity, registration, image). No fabricated maintenance or
/// odometer data. The active bike carries a single check badge, so selection
/// is never colour-only.
class BikeDashboardCard extends StatelessWidget {
  final Bike bike;
  final bool selected;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BikeDashboardCard({
    super.key,
    required this.bike,
    required this.selected,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.borderSubtle,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected ? AppShadow.redGlow : AppShadow.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BikeHero(
            image: bike.image,
            selected: selected,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selected) ...[
                  const _ActivePill(),
                  const SizedBox(height: AppSpacing.md),
                ],
                const Text(
                  'YOUR RIDE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  bike.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                if (bike.subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    bike.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                RcSecondaryButton(
                  label: 'View Details',
                  icon: Icons.chevron_right_rounded,
                  onPressed: onViewDetails,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BikeHero extends StatelessWidget {
  final String image;
  final bool selected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BikeHero({
    required this.image,
    required this.selected,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image.trim().isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            RcImage(image, fit: BoxFit.cover)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF22262E), Color(0xFF0E1013)],
                ),
              ),
              child: SizedBox.shrink(),
            ),
          if (!hasImage) ...[
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.22),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.sports_motorsports_rounded,
                size: 96,
                color: Color(0x52E31B23),
              ),
            ),
          ],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 64,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeroAction(
                  tooltip: 'Edit',
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                ),
                const SizedBox(width: AppSpacing.sm),
                _HeroAction(
                  tooltip: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeroAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        iconSize: 20,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        icon: Icon(icon, color: color),
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
            SizedBox(width: AppSpacing.xs),
            Text(
              'ACTIVE BIKE',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}