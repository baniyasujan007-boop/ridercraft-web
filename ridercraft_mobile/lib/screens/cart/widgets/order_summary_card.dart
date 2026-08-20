import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/rc_card.dart';

/// Strong order totals card: subtitle lines plus a visually dominant total.
///
/// Shipping is only shown when non-zero (the checkout has no shipping fee
/// today). Set [footNote] to override the default "confirmed at checkout"
/// disclaimer.
class OrderSummaryCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double shipping;
  final double total;
  final String? footNote;

  const OrderSummaryCard({
    super.key,
    required this.subtotal,
    required this.discount,
    this.shipping = 0,
    required this.total,
    this.footNote,
  });

  @override
  Widget build(BuildContext context) {
    return RcCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: subtotal),
          if (discount > 0)
            _SummaryRow(
              label: 'Discount',
              value: -discount,
              color: AppColors.success,
            ),
          if (shipping > 0) _SummaryRow(label: 'Shipping', value: shipping),
          const Divider(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Estimated total',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      Formatters.inr(total),
                      key: ValueKey<double>(total),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            footNote ?? 'Final price is confirmed securely at checkout.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;

  const _SummaryRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${value < 0 ? '- ' : ''}${Formatters.inr(value.abs())}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}