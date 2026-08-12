import 'package:flutter/material.dart';

import '../../../models/service_package.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/press_scale.dart';

/// A single service package card.
///
/// Shows only backend-truthful info: name, summary and the included items
/// (from the web client). No price, duration or availability — the backend
/// does not provide them, so the card says so honestly.
class ServicePackageCard extends StatelessWidget {
  final ServicePackage package;
  final VoidCallback onBookNow;

  const ServicePackageCard({
    super.key,
    required this.package,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      borderRadius: BorderRadius.circular(16),
      onTap: onBookNow,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              package.summary,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            if (package.includes.isNotEmpty) ...[
              for (final item in package.includes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 17,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Price confirmed during booking',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Book Now',
              icon: Icons.calendar_month_outlined,
              onPressed: onBookNow,
            ),
          ],
        ),
      ),
    );
  }
}
