import 'package:flutter/material.dart';

import '../../../models/order.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/press_scale.dart';
import '../../../widgets/rc_image.dart';
import '../order_status_style.dart';
import 'order_status_chip.dart';

/// Premium order card for the My Orders list: order number, date, item
/// preview with thumbnails, item count, total and the status/payment chips.
///
/// Uses [Expanded]/[Flexible] and ellipsis throughout so long order numbers,
/// product names and totals never overflow at narrow widths or large text.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  String get _shortId => order.id.length > 8
      ? order.id.substring(order.id.length - 8).toUpperCase()
      : order.id;

  @override
  Widget build(BuildContext context) {
    final previewItems = order.items.take(3).toList();
    final extra = order.items.length - previewItems.length;

    return Semantics(
      button: true,
      label:
          'Order ${order.id}, ${order.statusLabel}, ${order.paymentLabel}, '
          '${order.items.length} items, ${Formatters.inr(order.total)}',
      child: PressScale(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadow.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: Icon(
                      OrderStatusStyle.statusIcon(order.status),
                      color: OrderStatusStyle.statusColor(order.status),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Order #$_shortId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            if (order.createdAt != null)
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    Formatters.dateLabel(order.createdAt!),
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                '${order.items.length} '
                                '${order.items.length == 1 ? 'item' : 'items'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Formatters.inr(order.total),
                          maxLines: 1,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OrderStatusChip(status: order.status),
                  PaymentChip(
                    paymentStatus: order.paymentStatus,
                    paymentMethod: order.paymentMethod,
                  ),
                ],
              ),
              if (previewItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Row(
                    children: [
                      for (final item in previewItems)
                        Padding(
                          padding:
                              const EdgeInsets.only(right: AppSpacing.sm + 2),
                          child: _Thumb(url: item.image),
                        ),
                      Expanded(
                        child: Text(
                          extra > 0
                              ? '${previewItems.first.name} '
                                  '+$extra more'
                              : previewItems.first.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String url;

  const _Thumb({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: const Icon(
          Icons.sports_motorsports_rounded,
          size: 18,
          color: AppColors.textMuted,
        ),
      );
    }
    return RcImage(
      url,
      width: 38,
      height: 38,
      borderRadius: BorderRadius.circular(AppRadius.small),
    );
  }
}