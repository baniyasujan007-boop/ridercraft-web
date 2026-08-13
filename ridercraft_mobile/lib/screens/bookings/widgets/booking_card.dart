import 'package:flutter/material.dart';

import '../../../models/service_request.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';

/// Single booking row shown in the My Bookings list.
class BookingCard extends StatelessWidget {
  final ServiceRequest booking;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  Color _statusColor(String status) => switch (status) {
        'confirmed' => AppColors.info,
        'in_progress' => AppColors.accent,
        'completed' => AppColors.success,
        'cancelled' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.build_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      booking.packageLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _StatusChip(
                      label: booking.statusLabel,
                      color: _statusColor(booking.status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (booking.isEmergency) ...[
                _priorityLine(),
                const SizedBox(height: 6),
              ],
              if (booking.bikeModel.isNotEmpty) ...[
                _line(
                  icon: Icons.two_wheeler_rounded,
                  text: booking.bikeModel,
                ),
                const SizedBox(height: 6),
              ],
              _line(
                icon: Icons.calendar_month_outlined,
                text:
                    '${Formatters.dateLabelFromIso(booking.preferredDate)} at '
                    '${Formatters.timeLabelFromString(booking.preferredTime)}',
              ),
              if (booking.pickupAddress.isNotEmpty) ...[
                const SizedBox(height: 6),
                _line(
                  icon: Icons.location_on_outlined,
                  text: booking.pickupAddress,
                ),
              ],
              if (booking.assignedGarageName.isNotEmpty) ...[
                const SizedBox(height: 6),
                _line(
                  icon: Icons.garage_rounded,
                  text: booking.assignedGarageDistanceKm != null
                      ? '${booking.assignedGarageName} · '
                          '${booking.assignedGarageDistanceKm!.toStringAsFixed(1)} km'
                      : booking.assignedGarageName,
                ),
              ],
              if (booking.createdAt != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Requested ${Formatters.dateLabel(booking.createdAt!)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityLine() {
    return Row(
      children: [
        const Icon(Icons.emergency_rounded, size: 15, color: AppColors.error),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Emergency service',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

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
