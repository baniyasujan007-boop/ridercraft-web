import 'package:flutter/material.dart';

import '../../../models/service_package.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/press_scale.dart';
import '../../../widgets/section_header.dart';

/// "Services for your ride" preview on Home — the three real RiderCraft
/// service packages (basic / full / premium, mirroring the backend enum).
/// Tapping a card navigates to the existing Services tab.
class ServicesPreview extends StatelessWidget {
  final VoidCallback onServicesTap;

  const ServicesPreview({super.key, required this.onServicesTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Services for your ride',
          kicker: 'Service Studio',
          showDivider: false,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < servicePackages.length; i++) ...[
          _ServiceRow(
            package: servicePackages[i],
            onTap: onServicesTap,
          ),
          if (i < servicePackages.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final ServicePackage package;
  final VoidCallback onTap;

  const _ServiceRow({required this.package, required this.onTap});

  IconData get _icon => switch (package.type) {
        'full' => Icons.build_rounded,
        'premium' => Icons.auto_awesome_rounded,
        _ => Icons.settings_suggest_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: PressScale(
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
                ),
                child: Icon(_icon, color: AppColors.primaryLight, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      package.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}