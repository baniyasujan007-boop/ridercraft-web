import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_billing.dart';
import '../../providers/garage_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/rc_button.dart';

/// Garage payment methods the backend accepts.
const garagePaymentMethods = [
  'cash',
  'card',
  'upi',
  'ewallet',
  'bank_transfer',
  'other',
];

String garagePaymentMethodLabel(String method) => switch (method) {
      'cash' => 'Cash',
      'card' => 'Card',
      'upi' => 'UPI',
      'ewallet' => 'E-Wallet',
      'bank_transfer' => 'Bank Transfer',
      'other' => 'Other',
      _ => method,
    };

/// Opens the reusable garage payment sheet for a booking. Resolves `true`
/// when the payment state changed.
Future<bool?> showPaymentSheet(
  BuildContext context, {
  required String bookingId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PaymentSheet(bookingId: bookingId),
  );
}

class _PaymentSheet extends StatefulWidget {
  final String bookingId;

  const _PaymentSheet({required this.bookingId});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _reference = TextEditingController();
  String _method = 'cash';
  bool _done = false;

  late final AnimationController _successController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _reference.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _markPaid(GarageProvider garage) async {
    FocusScope.of(context).unfocus();
    final ok = await garage.updateBillingPayment(
      id: widget.bookingId,
      billingStatus: 'paid',
      paymentMethod: _method,
      paymentReference: _reference.text,
    );
    if (!mounted) return;
    if (ok) {
      _showSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            garage.paymentError ?? 'Could not update payment.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelPayment(GarageProvider garage) async {
    FocusScope.of(context).unfocus();
    final ok = await garage.updateBillingPayment(
      id: widget.bookingId,
      billingStatus: 'cancelled',
      paymentMethod: '',
    );
    if (!mounted) return;
    if (ok) {
      _showSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            garage.paymentError ?? 'Could not cancel the payment.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccess() {
    setState(() => _done = true);
    _successController.forward();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<GarageProvider>();
    final billing = garage.bookingById(widget.bookingId)?.billing;
    final saving = garage.paymentSaving;
    final locked = saving || _done;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: _done
                ? _SuccessView(controller: _successController)
                : _content(garage, billing, locked),
          ),
        ),
      ),
    );
  }

  Widget _content(GarageProvider garage, ServiceBilling? billing, bool locked) {
    final saving = garage.paymentSaving;
    final billed = billing != null && billing.isIssued;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Payment',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          billed
              ? 'Bill total ${Formatters.inr(billing.total)}'
              : 'No issued bill to collect payment for yet.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        if (billed) ...[
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'PAYMENT METHOD',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final method in garagePaymentMethods)
                _MethodChip(
                  label: garagePaymentMethodLabel(method),
                  selected: _method == method,
                  onTap: locked ? null : () => setState(() => _method = method),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _reference,
            enabled: !locked,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Payment reference (optional)',
              prefixIcon: const Icon(Icons.tag_rounded, size: 19),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          RcButton(
            label: locked && saving ? 'Updating…' : 'Mark Paid',
            icon: Icons.check_circle_outline_rounded,
            loading: saving,
            onPressed: locked ? null : () => _markPaid(garage),
          ),
          const SizedBox(height: AppSpacing.md),
          RcSecondaryButton(
            label: 'Cancel Payment',
            icon: Icons.block_rounded,
            onPressed: locked ? null : () => _cancelPayment(garage),
          ),
        ] else
          const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _MethodChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Confirmation state shown briefly after a successful payment action.
class _SuccessView extends StatelessWidget {
  final AnimationController controller;

  const _SuccessView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 72,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Payment updated',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'The bill status was changed.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}