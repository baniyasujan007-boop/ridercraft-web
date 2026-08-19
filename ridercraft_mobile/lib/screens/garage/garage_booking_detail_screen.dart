import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_request.dart';
import '../../providers/garage_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/rc_button.dart';
import '../../widgets/rc_card.dart';
import '../../widgets/rc_entrance.dart';
import 'billing_sheet.dart';
import 'payment_sheet.dart';
import 'widgets/garage_chips.dart';

/// Garage booking detail: customer, bike/service, pickup info, the animated
/// status stepper (requested → confirmed → in_progress → completed), garage
/// note, billing and payment. All actions use the existing backend through
/// [GarageProvider].
class GarageBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const GarageBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<GarageBookingDetailScreen> createState() =>
      _GarageBookingDetailScreenState();
}

class _GarageBookingDetailScreenState extends State<GarageBookingDetailScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _noteInitialized = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _initNote(String note) {
    if (_noteInitialized) return;
    _noteInitialized = true;
    _noteController.text = note;
  }

  Future<void> _saveNote(GarageProvider garage, String bookingId) async {
    final booking = garage.bookingById(bookingId);
    if (booking == null) return;
    await garage.respondToBooking(
      id: bookingId,
      status: booking.status,
      garageNote: _noteController.text,
      onSuccess: (message) => _toast(context, message, success: true),
    );
  }

  Future<void> _changeStatus(
    GarageProvider garage,
    String bookingId,
    String status,
  ) async {
    final booking = garage.bookingById(bookingId);
    if (booking == null || status == booking.status) return;
    final ok = await garage.respondToBooking(
      id: bookingId,
      status: status,
      garageNote: _noteController.text,
      onSuccess: (message) => _toast(context, message, success: true),
    );
    if (!ok && mounted) {
      _toast(
        context,
        garage.responseError ?? 'Could not update the booking.',
        success: false,
      );
    }
  }

  Future<void> _openBilling(BuildContext context, String bookingId) async {
    await showBillingSheet(context, bookingId: bookingId);
  }

  Future<void> _openPayment(BuildContext context, String bookingId) async {
    await showPaymentSheet(context, bookingId: bookingId);
  }

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<GarageProvider>();
    final booking = garage.bookingById(widget.bookingId);

    if (booking == null) {
      if (garage.loading) {
        return const Scaffold(body: LoadingView(label: 'Loading booking…'));
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: ErrorView(
          message: 'This booking is no longer assigned to your garage.',
          onRetry: () => context.read<GarageProvider>().loadBookings(),
        ),
      );
    }

    _initNote(booking.garageNote);

    final canEditStatus = !garage.responding && booking.status != 'completed';

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Detail')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          RcEntrance(child: _BookingHeroCard(booking: booking)),
          const SizedBox(height: AppSpacing.lg),
          RcEntrance(
            child: _StatusWorkflowCard(
              booking: booking,
              onTapStep: canEditStatus
                  ? (status) => _changeStatus(garage, booking.id, status)
                  : null,
              onSaveNote: () => _saveNote(garage, booking.id),
              noteController: _noteController,
              onCancel: booking.status == 'cancelled' ||
                      booking.status == 'completed'
                  ? null
                  : () => _changeStatus(garage, booking.id, 'cancelled'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          RcEntrance(child: _CustomerCard(booking: booking)),
          const SizedBox(height: AppSpacing.lg),
          RcEntrance(child: _ServiceCard(booking: booking)),
          const SizedBox(height: AppSpacing.lg),
          RcEntrance(
            child: _BillingCard(
              booking: booking,
              onEditBill: () => _openBilling(context, booking.id),
              onPayment: booking.billing.isIssued
                  ? () => _openPayment(context, booking.id)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

void _toast(BuildContext context, String message, {required bool success}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _BookingHeroCard extends StatelessWidget {
  final ServiceRequest booking;

  const _BookingHeroCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final idShort = booking.id.length > 10
        ? booking.id.substring(0, 10).toUpperCase()
        : booking.id.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3646), Color(0xFF141A22)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Booking #$idShort',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GarageStatusChip(status: booking.status),
            ],
          ),
          if (booking.isEmergency) ...[
            const SizedBox(height: AppSpacing.md),
            const GarageEmergencyBadge(),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            booking.bikeModel.isNotEmpty
                ? '${booking.packageLabel} · ${booking.bikeModel}'
                : booking.packageLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
          if (booking.createdAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Requested ${Formatters.fullDateLabel(booking.createdAt!)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusWorkflowCard extends StatelessWidget {
  final ServiceRequest booking;
  final void Function(String status)? onTapStep;
  final VoidCallback onSaveNote;
  final TextEditingController noteController;
  final VoidCallback? onCancel;

  const _StatusWorkflowCard({
    required this.booking,
    required this.onTapStep,
    required this.onSaveNote,
    required this.noteController,
    required this.onCancel,
  });

  static const _steps = ['requested', 'confirmed', 'in_progress', 'completed'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexWhere((s) => s == booking.status);
    final isCancelled = booking.status == 'cancelled';

    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Stepper(
            steps: _steps,
            currentIndex: currentIndex,
            cancelled: isCancelled,
            enabled: onTapStep != null,
            onTapStep: onTapStep,
          ),
          if (isCancelled) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'This booking was cancelled.',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: noteController,
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Garage note',
              hintText: 'Notes visible to the customer',
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: RcSecondaryButton(
                  label: 'Save Note',
                  icon: Icons.save_outlined,
                  onPressed: onSaveNote,
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: RcButton(
                    label: 'Cancel',
                    icon: Icons.close_rounded,
                    onPressed: onCancel,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Animated horizontal stepper with connected steps.
class _Stepper extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;
  final bool cancelled;
  final bool enabled;
  final void Function(String status)? onTapStep;

  const _Stepper({
    required this.steps,
    required this.currentIndex,
    required this.cancelled,
    required this.enabled,
    required this.onTapStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: i <= currentIndex && !cancelled
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          _StepDot(
            label: _label(steps[i]),
            reached: i <= currentIndex && !cancelled,
            active: i == currentIndex && !cancelled,
            onTap: enabled && !cancelled
                ? () => onTapStep?.call(steps[i])
                : null,
          ),
        ],
      ],
    );
  }

  static String _label(String step) => switch (step) {
        'confirmed' => 'Confirmed',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        _ => 'Requested',
      };
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool reached;
  final bool active;
  final VoidCallback? onTap;

  const _StepDot({
    required this.label,
    required this.reached,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = reached
        ? AppColors.primary
        : (active ? AppColors.primaryLight : AppColors.textMuted);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: active ? 38 : 32,
            height: active ? 38 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reached ? AppColors.primary : AppColors.surfaceAlt,
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
                width: active ? 2 : 1,
              ),
            ),
            child: Center(
              child: reached
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                  : Icon(Icons.circle, size: 8, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final ServiceRequest booking;

  const _CustomerCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CUSTOMER',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (booking.customerName.isNotEmpty)
            _tile(Icons.person_outline_rounded, 'Customer', booking.customerName),
          if (booking.customerContact.isNotEmpty)
            _tile(Icons.phone_outlined, 'Contact', booking.customerContact),
          if (booking.customerEmail.isNotEmpty)
            _tile(Icons.alternate_email_rounded, 'Email', booking.customerEmail),
          if (booking.pickupAddress.isNotEmpty)
            _tile(Icons.location_on_outlined, 'Pickup', booking.pickupAddress),
          if (booking.pickupLatitude != 0 || booking.pickupLongitude != 0)
            _tile(
              Icons.place_outlined,
              'Location',
              '${booking.pickupLatitude}, ${booking.pickupLongitude}',
            ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
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

class _ServiceCard extends StatelessWidget {
  final ServiceRequest booking;

  const _ServiceCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SERVICE',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _row(Icons.build_outlined, booking.packageLabel),
          if (booking.bikeModel.isNotEmpty)
            _row(Icons.two_wheeler_rounded, booking.bikeModel),
          if (booking.preferredDate.isNotEmpty)
            _row(
              Icons.calendar_month_outlined,
              '${Formatters.dateLabelFromIso(booking.preferredDate)} at '
              '${Formatters.timeLabelFromString(booking.preferredTime)}',
            ),
          _row(
            Icons.priority_high_rounded,
            '${booking.priorityLabel} priority',
            color: booking.isEmergency ? AppColors.error : null,
          ),
          if (booking.breakdownIssue.isNotEmpty)
            _row(Icons.report_problem_outlined, 'Breakdown: ${booking.breakdownIssue}'),
          if (booking.notes.isNotEmpty) _row(Icons.notes_rounded, booking.notes),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontSize: 14,
                fontWeight: color == null ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  final ServiceRequest booking;
  final VoidCallback onEditBill;
  final VoidCallback? onPayment;

  const _BillingCard({
    required this.booking,
    required this.onEditBill,
    required this.onPayment,
  });

  @override
  Widget build(BuildContext context) {
    final billing = booking.billing;
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'BILLING',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              GarageBillingChip(billingStatus: billing.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (billing.isIssued || billing.isPaid || billing.isCancelled) ...[
            _billLine('Labor charge', Formatters.inr(billing.laborCharge)),
            if (billing.items.isNotEmpty) ...[
              for (final item in billing.items)
                _billLine(
                  item.name,
                  '${item.quantity} × ${Formatters.inr(item.unitPrice)}',
                ),
            ],
            _divider(),
            _billLine('Subtotal', Formatters.inr(billing.subtotal)),
            _billLine('Tax', Formatters.inr(billing.tax)),
            if (billing.discount > 0)
              _billLine('Discount', '-${Formatters.inr(billing.discount)}'),
            _divider(),
            _billLine('Total', Formatters.inr(billing.total), emphasized: true),
            if (billing.isPaid) ...[
              const SizedBox(height: AppSpacing.sm),
              _billLine(
                'Paid via',
                billing.paymentMethodLabel,
              ),
              if (billing.paymentReference.isNotEmpty)
                _billLine('Reference', billing.paymentReference),
            ],
          ] else
            const Text(
              'No bill issued yet. Create a bill to send the customer their '
              'service invoice.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: RcSecondaryButton(
                  label: billing.isIssued || billing.isPaid
                      ? 'Edit Bill'
                      : 'Create Bill',
                  icon: Icons.receipt_long_outlined,
                  onPressed: onEditBill,
                ),
              ),
              if (onPayment != null) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: RcButton(
                    label: 'Payment',
                    icon: Icons.payment_rounded,
                    onPressed: onPayment,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _billLine(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasized ? AppColors.primaryLight : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: Divider(height: 1, color: AppColors.border),
      );
}