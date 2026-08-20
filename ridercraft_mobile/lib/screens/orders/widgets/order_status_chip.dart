import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../order_status_style.dart';

/// Small rounded status chip with the status colour + a leading icon.
/// The label text carries the meaning so state is never inferred from colour
/// alone.
class OrderStatusChip extends StatelessWidget {
  final String status;
  final bool emphasized;

  const OrderStatusChip({
    super.key,
    required this.status,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = OrderStatusStyle.statusColor(status);
    return Semantics(
      label: 'Order status: ${OrderStatusStyle.stepLabel(status)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2,
             vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              OrderStatusStyle.statusIcon(status),
              size: 14,
              color: color,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  OrderStatusStyle.stepLabel(status),
                  maxLines: 1,
                  style: TextStyle(
                    color: emphasized ? AppColors.textPrimary : color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Payment status chip: green when paid, amber when refunded, muted when
/// pending — with the payment method always spelled out as text.
class PaymentChip extends StatelessWidget {
  final String paymentStatus;
  final String paymentMethod;

  const PaymentChip({
    super.key,
    required this.paymentStatus,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final color = OrderStatusStyle.paymentStatusColor(paymentStatus);
    return Semantics(
      label: 'Payment $paymentStatus via '
          '${OrderStatusStyle.paymentMethodLabel(paymentMethod)}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(OrderStatusStyle.paymentMethodIcon(paymentMethod),
                size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${OrderStatusStyle.paymentMethodLabel(paymentMethod)} · '
                  '${paymentStatus == 'paid'
                      ? 'Paid'
                      : paymentStatus == 'refunded'
                          ? 'Refunded'
                          : 'Pending'}',
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}