import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_draft.dart';
import '../../providers/booking_provider.dart';
import '../../routes/route_names.dart';
import '../../services/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

/// Final review before submitting the booking to `POST /service-requests`.
///
/// Shows only backend-truthful values. There is no price, discount or coupon
/// because the backend does not support them for service bookings.
class BookingReviewScreen extends StatelessWidget {
  final BookingDraft draft;

  const BookingReviewScreen({super.key, required this.draft});

  Future<void> _confirm(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final bookingProvider = context.read<BookingProvider>();

    try {
      final booking = await bookingProvider.createBooking(
        packageType: draft.packageType,
        bikeModel: draft.bikeModel,
        preferredDate: draft.dateValue!,
        preferredTime: draft.timeValue!,
        pickupAddress: draft.pickupAddress,
        pickupLocation: draft.toPickupLocation(),
        contactNumber: draft.contactNumber,
        priority: draft.priority,
        breakdownIssue: draft.breakdownIssue,
        notes: draft.notes,
      );
      if (!context.mounted) return;
      navigator.pushNamedAndRemoveUntil(
        RouteNames.bookingSuccess,
        (route) => route.isFirst,
        arguments: booking,
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.select<BookingProvider, bool>(
      (provider) => provider.submitting,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Review Booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReviewTile(
            icon: Icons.build_outlined,
            label: 'Service',
            value: draft.packageLabel,
          ),
          _ReviewTile(
            icon: Icons.two_wheeler_rounded,
            label: 'Bike',
            value: draft.bikeModel,
          ),
          _ReviewTile(
            icon: Icons.calendar_month_outlined,
            label: 'Date',
            value: Formatters.fullDateLabel(draft.preferredDate!),
          ),
          _ReviewTile(
            icon: Icons.schedule_rounded,
            label: 'Time',
            value: Formatters.timeOfDayLabel(draft.preferredTime!),
          ),
          _ReviewTile(
            icon: Icons.location_on_outlined,
            label: 'Pickup address',
            value: draft.pickupAddress,
          ),
          _ReviewTile(
            icon: Icons.place_outlined,
            label: 'Coordinates',
            value:
                '${draft.latitude?.toStringAsFixed(6)}, ${draft.longitude?.toStringAsFixed(6)}',
          ),
          _ReviewTile(
            icon: Icons.phone_outlined,
            label: 'Contact',
            value: draft.contactNumber,
          ),
          _ReviewTile(
            icon: Icons.event_available_rounded,
            label: 'Priority',
            value: draft.isEmergency ? 'Emergency' : 'Normal',
          ),
          if (draft.breakdownIssue.isNotEmpty)
            _ReviewTile(
              icon: Icons.build_rounded,
              label: 'Breakdown issue',
              value: draft.breakdownIssue,
            ),
          if (draft.notes.isNotEmpty)
            _ReviewTile(
              icon: Icons.notes_rounded,
              label: 'Notes',
              value: draft.notes,
            ),
          const SizedBox(height: 12),
          const Text(
            'The exact service price is confirmed by RiderCraft when your '
            'booking is accepted.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Confirm Booking',
            icon: Icons.check_circle_outline_rounded,
            loading: submitting,
            onPressed: submitting ? null : () => _confirm(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewTile({
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
