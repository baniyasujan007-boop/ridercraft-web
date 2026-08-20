import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/promo.dart';
import '../../../providers/cart_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/rc_card.dart';
import '../../../widgets/rc_entrance.dart';

/// Premium coupon / promo code section shared by the cart and checkout.
///
/// The backend stays the source of truth: [CartProvider.applyPromo] validates
/// against the API and only the server-computed discount amount is shown.
class PromoSection extends StatefulWidget {
  final TextEditingController controller;

  const PromoSection({super.key, required this.controller});

  @override
  State<PromoSection> createState() => _PromoSectionState();
}

class _PromoSectionState extends State<PromoSection> {
  String? _localError;

  Future<void> _apply() async {
    final cart = context.read<CartProvider>();
    final code = widget.controller.text.trim();
    if (code.isEmpty) {
      setState(() => _localError = 'Enter a promo code first.');
      return;
    }
    setState(() => _localError = null);
    final ok = await cart.applyPromo(code);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Coupon applied.')));
    } else {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              cart.promoError?.isNotEmpty == true
                  ? cart.promoError!
                  : 'That promo code could not be applied.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final applied = cart.appliedPromo;
    final errorText = _localError ?? cart.promoError;

    return RcCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coupon / Promo code',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      applied == null
                          ? 'Apply a code to unlock savings.'
                          : 'Discount confirmed by RiderCraft.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: widget.controller,
            enabled: !cart.isApplyingPromo,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Enter code',
              suffixIcon: cart.isApplyingPromo
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: applied != null ? null : _apply,
                      style: TextButton.styleFrom(
                        foregroundColor: applied != null
                            ? AppColors.textMuted
                            : AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                      ),
                      child: const Text('APPLY'),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: applied != null
                ? _AppliedPromo(promo: applied, onRemove: cart.removePromo)
                : errorText != null
                ? _PromoError(message: _friendlyPromoError(errorText))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static String _friendlyPromoError(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 'That promo code could not be applied.';
    return text;
  }
}

class _AppliedPromo extends StatelessWidget {
  final PromoValidation promo;
  final VoidCallback onRemove;

  const _AppliedPromo({required this.promo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return RcEntrance(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.code.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '-${Formatters.inr(promo.discountAmount)} on this order',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoError extends StatelessWidget {
  final String message;
  const _PromoError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 17,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}