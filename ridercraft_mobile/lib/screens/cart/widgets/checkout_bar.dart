import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/rc_button.dart';

/// Sticky bottom purchase area: the dominant total plus a primary CTA.
///
/// Optionally shows a non-blocking [notice] (e.g. "some items need
/// attention") above the row. The button is disabled automatically when
/// [onCheckout] is null or [loading] is true.
class CheckoutBar extends StatelessWidget {
  final double total;
  final VoidCallback? onCheckout;
  final bool loading;
  final String label;
  final IconData icon;
  final String? notice;

  const CheckoutBar({
    super.key,
    required this.total,
    required this.onCheckout,
    this.loading = false,
    this.label = 'PROCEED TO CHECKOUT',
    this.icon = Icons.lock_outline_rounded,
    this.notice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm + 2,
            AppSpacing.lg,
            AppSpacing.sm + 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (notice != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        notice!,
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Text(
                              Formatters.inr(total),
                              key: ValueKey<double>(total),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 2,
                    child: RcButton(
                      label: label,
                      icon: icon,
                      loading: loading,
                      onPressed: loading ? null : onCheckout,
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
}