import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Compact status pill (Requested / Confirmed / In Progress / Completed /
/// Cancelled) using the same colour language as the customer bookings screens.
class GarageStatusChip extends StatelessWidget {
  final String status;

  const GarageStatusChip({super.key, required this.status});

  String get label => switch (status) {
        'confirmed' => 'Confirmed',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        _ => 'Requested',
      };

  Color get color => switch (status) {
        'confirmed' => AppColors.info,
        'in_progress' => AppColors.accent,
        'completed' => AppColors.success,
        'cancelled' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return _Pill(color: color, label: label);
  }
}

/// Billing status pill (Unbilled / Issued / Paid / Cancelled).
class GarageBillingChip extends StatelessWidget {
  final String billingStatus;

  const GarageBillingChip({super.key, required this.billingStatus});

  String get label => switch (billingStatus) {
        'issued' => 'Bill Issued',
        'paid' => 'Paid',
        'cancelled' => 'Cancelled',
        _ => 'Unbilled',
      };

  Color get color => switch (billingStatus) {
        'paid' => AppColors.success,
        'issued' => AppColors.warning,
        'cancelled' => AppColors.error,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return _Pill(color: color, label: label);
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final String label;

  const _Pill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Emergency banner for emergency-priority requests.
class GarageEmergencyBadge extends StatelessWidget {
  const GarageEmergencyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emergency_rounded, size: 14, color: AppColors.error),
          SizedBox(width: 5),
          Text(
            'EMERGENCY',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}