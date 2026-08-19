import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/press_scale.dart';

/// Sticky purchase area: quantity stepper (with the stock-aware cap), plus
/// "Buy Now" and "Add to Cart" CTAs. The add-to-cart CTA animates through a
/// loading spinner and a brief success check.
class PurchaseBar extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final bool outOfStock;
  final bool adding;
  final bool added;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  const PurchaseBar({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.outOfStock,
    required this.adding,
    required this.added,
    this.onDecrement,
    this.onIncrement,
    this.onAddToCart,
    this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 10, AppSpacing.lg, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: outOfStock
            ? _OutOfStockBar()
            : Row(
                children: [
                  _QuantityStepper(
                    quantity: quantity,
                    onDecrement: onDecrement,
                    onIncrement: onIncrement,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _BuyNowButton(onTap: onBuyNow)),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(child: _AddToCartButton(onTap: onAddToCart, adding: adding, added: added)),
                ],
              ),
      ),
    );
  }
}

class _OutOfStockBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'OUT OF STOCK',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepIcon(
            icon: Icons.remove_rounded,
            enabled: onDecrement != null,
            tooltip: 'Decrease quantity',
            onTap: onDecrement,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 30),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          _StepIcon(
            icon: Icons.add_rounded,
            enabled: onIncrement != null,
            tooltip: 'Increase quantity',
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final String tooltip;
  final VoidCallback? onTap;

  const _StepIcon({
    required this.icon,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: PressScale(onTap: enabled ? onTap : null, child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.textPrimary : AppColors.textMuted,
        ),
      )),
    );
  }
}

class _BuyNowButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _BuyNowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Buy Now',
              style: TextStyle(
                color: onTap == null
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool adding;
  final bool added;

  const _AddToCartButton({
    required this.onTap,
    required this.adding,
    required this.added,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = adding || onTap == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: disabled ? 0.75 : 1,
      child: PressScale(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            boxShadow: AppShadow.redGlow,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: added
                ? const _AddContent(
                    key: ValueKey('add-chk'),
                    color: Color(0xFF7CF29D),
                    icon: Icons.check_rounded,
                    label: 'Added',
                  )
                : adding
                ? const SizedBox(
                    key: ValueKey('add-spin'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const _AddContent(
                    key: ValueKey('add-default'),
                    color: Colors.white,
                    icon: Icons.shopping_bag_outlined,
                    label: 'Add to Cart',
                  ),
          ),
        ),
      ),
    );
  }
}

class _AddContent extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _AddContent({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}