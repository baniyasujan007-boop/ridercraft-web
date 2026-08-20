import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/rc_card.dart';
import '../../widgets/rc_image.dart';
import '../../widgets/staggered_entry.dart';
import 'order_status_style.dart';
import 'order_status_timeline.dart';
import 'widgets/order_status_chip.dart';

/// Full order breakdown: header, status timeline, items, payment and
/// delivery — driven entirely by the backend `Order` passed through
/// navigation. No invented statuses or delivery promises.
class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _section(0, _HeaderCard(order: order)),
                const SizedBox(height: AppSpacing.md),
                _section(1, _StatusCard(order: order)),
                if (order.items.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _section(2, _ItemsCard(items: order.items)),
                ],
                if (order.subtotal > 0 || order.total > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  _section(
                    3,
                    _PaymentCard(
                      order: order,
                      showDelivery: order.deliveryAddress.isNotEmpty ||
                          order.contactNumber.isNotEmpty,
                    ),
                  ),
                ],
                if (order.deliveryAddress.isNotEmpty ||
                    order.contactNumber.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _section(4, _DeliveryCard(order: order)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(int index, Widget child) {
    return StaggeredEntry(parent: _entrance, index: index, child: child);
  }
}

class _HeaderCard extends StatelessWidget {
  final Order order;

  const _HeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(
              OrderStatusStyle.statusIcon(order.status),
              color: OrderStatusStyle.statusColor(order.status),
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                if (order.createdAt != null)
                  Text(
                    Formatters.fullDateLabel(order.createdAt!),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: OrderStatusChip(status: order.status, emphasized: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Order order;

  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER STATUS',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OrderStatusTimeline(status: order.status),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final List<OrderItem> items;

  const _ItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ITEMS (${items.length})',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 20,
                color: AppColors.borderSubtle,
              ),
            _ItemRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final variantParts = [
      if (item.color.isNotEmpty) item.color,
      if (item.size.isNotEmpty) 'Size ${item.size}',
      if (item.variantSku.isNotEmpty) item.variantSku,
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ItemThumb(image: item.image),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (variantParts.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    variantParts,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  'Qty ${item.qty} × ${Formatters.inr(item.price)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Formatters.inr(item.price * item.qty),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
    );
  }
}

class _ItemThumb extends StatelessWidget {
  final String image;

  const _ItemThumb({required this.image});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: image.trim().isEmpty
            ? Container(
                color: AppColors.surfaceAlt,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.sports_motorsports_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              )
            : RcImage(
                image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Order order;
  final bool showDelivery;

  const _PaymentCard({required this.order, required this.showDelivery});

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYMENT',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TotalRow(label: 'Subtotal', value: order.subtotal),
          if (order.discount > 0)
            _TotalRow(
              label: 'Discount',
              value: -order.discount,
              color: AppColors.success,
            ),
          if (order.shipping > 0)
            _TotalRow(label: 'Shipping', value: order.shipping),
          if (order.tax > 0) _TotalRow(label: 'Tax', value: order.tax),
          const Divider(height: 22, color: AppColors.borderSubtle),
          _TotalRow(label: 'Total', value: order.total, bold: true),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PaymentChip(
                paymentStatus: order.paymentStatus,
                paymentMethod: order.paymentMethod,
              ),
              if (order.promoCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Coupon ${order.promoCode.toUpperCase()}',
                            maxLines: 1,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
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
                  color: bold ? AppColors.primary : textColor,
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Order order;

  const _DeliveryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (order.contactNumber.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.call_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    order.contactNumber,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}