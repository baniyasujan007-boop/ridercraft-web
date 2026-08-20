import 'package:flutter/material.dart';

import '../../../models/cart_item.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/press_scale.dart';
import '../../../widgets/rc_entrance.dart';
import '../../../widgets/rc_image.dart';
import 'stock_status.dart';

/// Premium cart line card.
///
/// Visual hierarchy: image → product → variant info → availability → price →
/// quantity. Entrances with a subtle fade/slide, animates the quantity and
/// price transitions, and plays a short exit animation before removal.
class CartItemCard extends StatefulWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  /// Stable identity so the card keeps its state (and never re-runs the
  /// entrance animation) while quantities or neighbours change.
  static String identityOf(CartItem item) =>
      '${item.product.id}|${item.variantId}|${item.color}|${item.size}';

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  bool _exiting = false;

  void _requestRemove() {
    if (_exiting) return;
    setState(() => _exiting = true);
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) widget.onRemove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final stock = resolveCartStock(item);
    final blocked = stock.status == CartStockStatus.outOfStock ||
        stock.status == CartStockStatus.unavailable;

    final card = AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInCubic,
      opacity: _exiting ? 0 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInCubic,
        scale: _exiting ? 0.96 : 1,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: blocked
                ? AppColors.surfaceAlt
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: blocked
                  ? AppColors.error.withValues(alpha: 0.28)
                  : AppColors.borderSubtle,
            ),
            boxShadow: AppShadow.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: RcImage(
                  item.product.image,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    if (_variantMeta(item).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _variantMeta(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _StockBadge(resolution: stock),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Text(
                                Formatters.inr(item.lineTotal),
                                key: ValueKey<int>(item.quantity),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Formatters.inr(item.unitPrice)} each',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _QuantityStepper(
                          quantity: item.quantity,
                          onDecrement: item.quantity > 1 && !blocked
                              ? widget.onDecrement
                              : null,
                          onIncrement: !blocked &&
                              item.quantity < stock.maxQuantity
                              ? widget.onIncrement
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _RemoveButton(onTap: _requestRemove),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return RcEntrance(child: card);
  }

  static String _variantMeta(CartItem item) {
    final parts = <String>[
      if (item.color.isNotEmpty) item.color,
      if (item.size.isNotEmpty) 'Size ${item.size}',
      if (item.variantSku.isNotEmpty) item.variantSku,
    ];
    return parts.join(' · ');
  }
}

class _StockBadge extends StatelessWidget {
  final StockResolution resolution;
  const _StockBadge({required this.resolution});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (resolution.status) {
      CartStockStatus.inStock => (AppColors.success, Icons.check_circle_rounded),
      CartStockStatus.outOfStock => (
          AppColors.error,
          Icons.remove_circle_outline_rounded,
        ),
      CartStockStatus.exceedsStock => (
          AppColors.warning,
          Icons.priority_high_rounded,
        ),
      CartStockStatus.unavailable => (
          AppColors.error,
          Icons.error_outline_rounded,
        ),
    };

    return Semantics(
      label: 'Availability: ${resolution.message}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                resolution.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
            constraints: const BoxConstraints(minWidth: 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                '$quantity',
                key: ValueKey<int>(quantity),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
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
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: PressScale(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      icon: const Icon(Icons.delete_outline_rounded, size: 17),
      label: const Text('Remove'),
    );
  }
}