import 'package:flutter/material.dart';

import '../../models/service_request.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

/// Booking detail rendered entirely from the [ServiceRequest] already returned
/// by `GET /service-requests/my`. The backend has no per-id booking endpoint,
/// so no extra fetch happens. No Cancel button — customers cannot cancel.
class BookingDetailScreen extends StatelessWidget {
  final ServiceRequest booking;

  const BookingDetailScreen({super.key, required this.booking});

  Color _statusColor(String status) => switch (status) {
        'confirmed' => AppColors.info,
        'in_progress' => AppColors.accent,
        'completed' => AppColors.success,
        'cancelled' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A3646), Color(0xFF141A22)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking #${booking.id.isEmpty ? '—' : booking.id.substring(0, booking.id.length > 10 ? 10 : booking.id.length).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  booking.statusLabel,
                  style: TextStyle(
                    color: _statusColor(booking.status),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _DetailTile(
            icon: Icons.build_outlined,
            label: 'Service',
            value: booking.packageLabel,
          ),
          if (booking.bikeModel.isNotEmpty)
            _DetailTile(
              icon: Icons.two_wheeler_rounded,
              label: 'Bike',
              value: booking.bikeModel,
            ),
          if (booking.preferredDate.isNotEmpty)
            _DetailTile(
              icon: Icons.calendar_month_outlined,
              label: 'Date',
              value: Formatters.dateLabelFromIso(booking.preferredDate),
            ),
          if (booking.preferredTime.isNotEmpty)
            _DetailTile(
              icon: Icons.schedule_rounded,
              label: 'Time',
              value: Formatters.timeLabelFromString(booking.preferredTime),
            ),
          if (booking.pickupAddress.isNotEmpty)
            _DetailTile(
              icon: Icons.location_on_outlined,
              label: 'Pickup address',
              value: booking.pickupAddress,
            ),
          if (booking.contactNumber.isNotEmpty)
            _DetailTile(
              icon: Icons.phone_outlined,
              label: 'Contact',
              value: booking.contactNumber,
            ),
          _DetailTile(
            icon: Icons.event_available_rounded,
            label: 'Priority',
            value: booking.priorityLabel,
          ),
          if (booking.breakdownIssue.isNotEmpty)
            _DetailTile(
              icon: Icons.build_rounded,
              label: 'Breakdown issue',
              value: booking.breakdownIssue,
            ),
          if (booking.notes.isNotEmpty)
            _DetailTile(
              icon: Icons.notes_rounded,
              label: 'Notes',
              value: booking.notes,
            ),
          if (booking.assignedGarageName.isNotEmpty)
            _DetailTile(
              icon: Icons.garage_rounded,
              label: 'Assigned garage',
              value: booking.assignedGarageDistanceKm != null
                  ? '${booking.assignedGarageName} '
                      '(${booking.assignedGarageDistanceKm!.toStringAsFixed(1)} km)'
                  : booking.assignedGarageName,
            ),
          if (booking.assignedGarageContact.isNotEmpty ||
              booking.assignedGarageEmail.isNotEmpty)
            _DetailTile(
              icon: Icons.phone_outlined,
              label: 'Garage contact',
              value: [
                if (booking.assignedGarageContact.isNotEmpty)
                  booking.assignedGarageContact,
                if (booking.assignedGarageEmail.isNotEmpty)
                  booking.assignedGarageEmail,
              ].join('\n'),
            ),
          if (booking.createdAt != null)
            _DetailTile(
              icon: Icons.history_rounded,
              label: 'Requested on',
              value: Formatters.fullDateLabel(booking.createdAt!),
            ),
          const SizedBox(height: 12),
          const Text(
            'Booking cancellation is handled by RiderCraft. You will be '
            'notified when the status changes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
