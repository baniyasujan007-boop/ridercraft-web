import 'package:flutter/material.dart';

import '../../models/service_request.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../main_scaffold.dart';

/// Shown after `POST /service-requests` succeeds.
class BookingSuccessScreen extends StatelessWidget {
  final ServiceRequest booking;

  const BookingSuccessScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 48,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Booking Confirmed!',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your service request has been submitted. We will contact you '
                        'to confirm the slot.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _row(
                              context,
                              'Booking ID',
                              booking.id.isEmpty
                                  ? '—'
                                  : '#${booking.id.substring(0, booking.id.length > 10 ? 10 : booking.id.length).toUpperCase()}',
                            ),
                            _row(context, 'Package', booking.packageLabel),
                            _row(
                              context,
                              'Bike',
                              booking.bikeModel.isEmpty
                                  ? '—'
                                  : booking.bikeModel,
                            ),
                            _row(
                              context,
                              'Date',
                              Formatters.dateLabelFromIso(booking.preferredDate),
                            ),
                            _row(
                              context,
                              'Time',
                              Formatters.timeLabelFromString(
                                booking.preferredTime,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: () {
                          MainScaffold.switchToTab(3);
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('View My Bookings'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          MainScaffold.switchToTab(0);
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Back to Home'),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
