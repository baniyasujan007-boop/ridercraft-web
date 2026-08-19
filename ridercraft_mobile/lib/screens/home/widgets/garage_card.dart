import 'package:flutter/material.dart';

import '../../../models/bike.dart';
import '../../../routes/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_button.dart';
import '../../../widgets/rc_card.dart';
import '../../../widgets/rc_image.dart';

/// Garage card on the Home screen.
///
/// With a stored motorcycle the rider's bike becomes a visual anchor
/// (image, name, year • cc • reg and a "View Garage" CTA). With an empty
/// garage a polished onboarding state invites the rider to add their bike via
/// the existing My Bikes flow.
class GarageCard extends StatelessWidget {
  final Bike? bike;

  const GarageCard({super.key, required this.bike});

  @override
  Widget build(BuildContext context) {
    return RcCard(
      padding: EdgeInsets.zero,
      onTap: bike == null ? null : () => _openGarage(context),
      child: bike == null ? _Onboarding() : _Garage(bike: bike!),
    );
  }

  static void _openGarage(BuildContext context) {
    Navigator.of(context).pushNamed(RouteNames.myBikes);
  }
}

class _Garage extends StatelessWidget {
  final Bike bike;

  const _Garage({required this.bike});

  @override
  Widget build(BuildContext context) {
    final hasImage = bike.image.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1D22), Color(0xFF12141A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  child: hasImage
                      ? RcImage(bike.image, fit: BoxFit.cover)
                      : const Icon(
                          Icons.sports_motorsports_rounded,
                          size: 32,
                          color: AppColors.primaryLight,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR GARAGE',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bike.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (bike.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        bike.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          RcSecondaryButton(
            label: 'View Garage',
            icon: Icons.chevron_right_rounded,
            onPressed: () => GarageCard._openGarage(context),
          ),
        ],
      ),
    );
  }
}

class _Onboarding extends StatelessWidget {
  const _Onboarding();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1D22), Color(0xFF12141A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR GARAGE',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add your motorcycle to unlock personalized '
                      'recommendations and services.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your garage powers faster service bookings.',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          RcButton(
            label: 'Add Your Bike',
            icon: Icons.sports_motorsports_rounded,
            onPressed: () => GarageCard._openGarage(context),
          ),
        ],
      ),
    );
  }
}