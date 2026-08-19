import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_button.dart';
import '../../../widgets/rc_entrance.dart';

/// Premium garage onboarding for riders with no motorcycles yet. Reuses the
/// existing add-motorcycle flow — no new API behaviour.
class EmptyGarage extends StatelessWidget {
  final VoidCallback onAdd;

  const EmptyGarage({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: RcEntrance(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF20242B), Color(0xFF101318)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadow.card,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.sports_motorsports_rounded,
                      size: 54,
                      color: AppColors.primary.withValues(alpha: 0.9),
                    ),
                    Positioned(
                      right: 18,
                      top: 18,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const Text(
                'YOUR GARAGE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'No bikes added yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add your bike to book services faster.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.92),
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              RcButton(
                label: 'Add Motorcycle',
                icon: Icons.add_rounded,
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
