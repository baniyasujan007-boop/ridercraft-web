import 'package:flutter/material.dart';

import '../../../models/service_request.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../utils/formatters.dart';
import 'garage_chips.dart';

/// Garage booking row: customer, bike, package, priority, service status and
/// billing status. Used on the Dashboard and the Bookings tab. Emergency
/// requests are made visually prominent with the red banner.
class GarageBookingCard extends StatelessWidget {
  final ServiceRequest booking;
  final VoidCallback onTap;

  const GarageBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customer = booking.customerName;
    final title = customer.isNotEmpty ? customer : booking.bikeModel;
    final subtitle = customer.isNotEmpty ? booking.bikeModel : '';

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: booking.isEmergency ? AppColors.error : AppColors.borderSubtle,
              width: booking.isEmergency ? 1.2 : 1,
            ),
            boxShadow: booking.isEmergency ? _emergencyGlow : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(title),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(child: GarageStatusChip(status: booking.status)),
                ],
              ),
              if (booking.isEmergency) ...[
                const SizedBox(height: AppSpacing.sm),
                const GarageEmergencyBadge(),
              ],
              const SizedBox(height: AppSpacing.md),
              _line(
                icon: Icons.build_outlined,
                text: booking.packageLabel,
              ),
              if (booking.preferredDate.isNotEmpty) ...[
                const SizedBox(height: 6),
                _line(
                  icon: Icons.calendar_month_outlined,
                  text:
                      '${Formatters.dateLabelFromIso(booking.preferredDate)} · '
                      '${Formatters.timeLabelFromString(booking.preferredTime)}',
                ),
              ],
              if (booking.pickupAddress.isNotEmpty) ...[
                const SizedBox(height: 6),
                _line(
                  icon: Icons.location_on_outlined,
                  text: booking.pickupAddress,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Flexible(child: GarageBillingChip(billingStatus: booking.billing.status)),
                  const Spacer(),
                  if (booking.createdAt != null)
                    Text(
                      '● ${Formatters.dateLabel(booking.createdAt!)}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String title) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          title.isEmpty ? '?' : title.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _line({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  static const List<BoxShadow> _emergencyGlow = [
    BoxShadow(
      color: Color(0x29454040),
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];
}