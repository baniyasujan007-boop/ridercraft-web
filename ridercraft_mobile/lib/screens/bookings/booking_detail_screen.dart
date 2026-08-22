import 'package:flutter/material.dart';

import '../../../models/service_request.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/rc_card.dart';
import '../../../widgets/rc_entrance.dart';
import '../bookings/widgets/booking_status_timeline.dart';

/// Booking detail rendered entirely from the [ServiceRequest] already returned
/// by `GET /service-requests/my`. The backend has no per-id booking endpoint,
/// so no extra fetch happens. No Cancel button — customers cannot cancel.
class BookingDetailScreen extends StatefulWidget {
  final ServiceRequest booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) => switch (status) {
        'confirmed' => AppColors.info,
        'in_progress' => AppColors.accent,
        'completed' => AppColors.success,
        'cancelled' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.booking.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: CustomScrollView(
        slivers: [
          // Hero header with status
          SliverToBoxAdapter(
            child: RcEntrance(
              child: _buildHeroHeader(statusColor),
            ),
          ),
          // Status timeline
          SliverToBoxAdapter(
            child: RcEntrance(
              offset: 18,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: BookingStatusTimeline(status: widget.booking.status),
              ),
            ),
          ),
          // Details sections
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            sliver: SliverList.separated(
              itemCount: 1,
              separatorBuilder: (_, _) => const SizedBox.shrink(),
              itemBuilder: (context, _) => RcEntrance(
                offset: 18,
                child: _buildDetailsSections(statusColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(Color statusColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.25),
            AppColors.surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.hero),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(
                  Icons.build_outlined,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #${widget.booking.id.isEmpty ? '—' : widget.booking.id.substring(0, widget.booking.id.length > 10 ? 10 : widget.booking.id.length).toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.booking.packageLabel,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.booking.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.booking.createdAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Requested ${Formatters.fullDateLabel(widget.booking.createdAt!)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsSections(Color statusColor) {
    return Column(
      children: [
        // Service & Bike
        RcCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service & Bike',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailTile(
                  icon: Icons.build_outlined,
                  label: 'Service',
                  value: widget.booking.packageLabel,
                ),
                if (widget.booking.bikeModel.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _DetailTile(
                    icon: Icons.two_wheeler_rounded,
                    label: 'Bike',
                    value: widget.booking.bikeModel,
                  ),
                ],
                if (widget.booking.isEmergency) ...[
                  const SizedBox(height: AppSpacing.md),
                  _PriorityLine(),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Schedule & Location
        RcCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule & Location',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (widget.booking.preferredDate.isNotEmpty)
                  _DetailTile(
                    icon: Icons.calendar_month_outlined,
                    label: 'Preferred Date',
                    value: Formatters.dateLabelFromIso(widget.booking.preferredDate),
                  ),
                if (widget.booking.preferredTime.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _DetailTile(
                    icon: Icons.schedule_rounded,
                    label: 'Preferred Time',
                    value: Formatters.timeLabelFromString(widget.booking.preferredTime),
                  ),
                ],
                if (widget.booking.pickupAddress.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _DetailTile(
                    icon: Icons.location_on_outlined,
                    label: 'Pickup Address',
                    value: widget.booking.pickupAddress,
                  ),
                ],
                if (widget.booking.contactNumber.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _DetailTile(
                    icon: Icons.phone_outlined,
                    label: 'Contact',
                    value: widget.booking.contactNumber,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Optional details (priority, breakdown issue, notes)
        if (widget.booking.priority == 'emergency' ||
            widget.booking.breakdownIssue.isNotEmpty ||
            widget.booking.notes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          RcCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DetailTile(
                    icon: Icons.event_available_rounded,
                    label: 'Priority',
                    value: widget.booking.priorityLabel,
                  ),
                  if (widget.booking.breakdownIssue.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _DetailTile(
                      icon: Icons.build_rounded,
                      label: 'Breakdown Issue',
                      value: widget.booking.breakdownIssue,
                    ),
                  ],
                  if (widget.booking.notes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _DetailTile(
                      icon: Icons.notes_rounded,
                      label: 'Notes',
                      value: widget.booking.notes,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        // Garage info
        if (widget.booking.assignedGarageName.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          RcCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Garage',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DetailTile(
                    icon: Icons.garage_rounded,
                    label: 'Assigned garage',
                    value: widget.booking.assignedGarageDistanceKm != null
                        ? '${widget.booking.assignedGarageName} (${widget.booking.assignedGarageDistanceKm!.toStringAsFixed(1)} km)'
                        : widget.booking.assignedGarageName,
                  ),
                  if (widget.booking.assignedGarageContact.isNotEmpty ||
                      widget.booking.assignedGarageEmail.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _DetailTile(
                      icon: Icons.phone_outlined,
                      label: 'Garage contact',
                      value: [
                        if (widget.booking.assignedGarageContact.isNotEmpty)
                          widget.booking.assignedGarageContact,
                        if (widget.booking.assignedGarageEmail.isNotEmpty)
                          widget.booking.assignedGarageEmail,
                      ].join('\n'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        // Billing
        if (widget.booking.billing.isIssued || widget.booking.billing.isPaid) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildBillingSection(),
        ],

        const SizedBox(height: AppSpacing.lg),

        // Footer note
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Booking cancellation is handled by RiderCraft. You will be '
                  'notified when the status changes.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillingSection() {
    final billing = widget.booking.billing;
    final isPaid = billing.isPaid;
    final statusColor = isPaid ? AppColors.success : AppColors.info;

    return RcCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Billing',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    billing.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (billing.items.isNotEmpty) ...[
              ...billing.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '×${item.quantity}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      Formatters.inr(item.total),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
              const Divider(height: AppSpacing.lg),

              _BillingRow(
                label: 'Labor',
                value: Formatters.inr(billing.laborCharge),
              ),
              _BillingRow(
                label: 'Subtotal',
                value: Formatters.inr(billing.subtotal),
              ),
              if (billing.discount > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                _BillingRow(
                  label: 'Discount',
                  value: '-${Formatters.inr(billing.discount)}',
                  valueColor: AppColors.success,
                ),
              ],
              _BillingRow(
                label: 'Tax',
                value: Formatters.inr(billing.tax),
              ),
              const Divider(height: AppSpacing.lg),
              _BillingRow(
                label: 'Total',
                value: Formatters.inr(billing.total),
                isTotal: true,
              ),
            ] else ...[
              const Text(
                'Bill details will appear here once the garage issues the invoice.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],

            if (billing.paymentMethod.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.lg),
              _BillingRow(
                label: 'Payment Method',
                value: billing.paymentMethodLabel,
              ),
              if (billing.paymentReference.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _BillingRow(
                  label: 'Reference',
                  value: billing.paymentReference,
                ),
              ],
              if (billing.paidAt != null) ...[
                const SizedBox(height: AppSpacing.md),
                _BillingRow(
                  label: 'Paid On',
                  value: Formatters.fullDateLabel(billing.paidAt!),
                ),
              ],
            ],
          ],
        ),
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
    return Row(
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
    );
  }
}

class _PriorityLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.emergency_rounded,
            size: 20,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Priority',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Emergency Service',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BillingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const _BillingRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? (isTotal ? AppColors.textPrimary : AppColors.textPrimary),
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}