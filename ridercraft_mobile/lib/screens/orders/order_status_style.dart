import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Single source of truth for the backend-supported order/payment statuses.
///
/// Order status: placed, processing, shipped, delivered (Order.js enum).
/// Payment status: pending, paid, refunded (Order.js enum).
/// Payment method: cod, card, ewallet (Order.js enum).
abstract final class OrderStatusStyle {
  static const List<String> steps = [
    'placed',
    'processing',
    'shipped',
    'delivered',
  ];

  static const List<String> stepLabels = [
    'Placed',
    'Processing',
    'Shipped',
    'Delivered',
  ];

  /// Index of [status] inside [steps]; unknown values clamp to the first
  /// step (the backend only emits the four supported values).
  static int stepIndex(String status) {
    final index = steps.indexOf(status);
    return index < 0 ? 0 : index;
  }

  static String stepLabel(String status) {
    final index = steps.indexOf(status);
    return index < 0 ? 'Placed' : stepLabels[index];
  }

  static IconData statusIcon(String status) => switch (status) {
        'processing' => Icons.inventory_2_outlined,
        'shipped' => Icons.local_shipping_outlined,
        'delivered' => Icons.verified_outlined,
        _ => Icons.receipt_long_outlined,
      };

  static Color statusColor(String status) => switch (status) {
        'processing' => AppColors.accent,
        'shipped' => AppColors.primaryLight,
        'delivered' => AppColors.success,
        _ => AppColors.info,
      };

  static Color paymentStatusColor(String status) => switch (status) {
        'paid' => AppColors.success,
        'refunded' => AppColors.warning,
        _ => AppColors.textSecondary,
      };

  static String paymentMethodLabel(String method) => switch (method) {
        'card' => 'Card',
        'ewallet' => 'Wallet',
        'cod' => 'Cash on delivery',
        _ => 'Payment',
      };

  static IconData paymentMethodIcon(String method) => switch (method) {
        'card' => Icons.credit_card_rounded,
        'ewallet' => Icons.account_balance_wallet_rounded,
        _ => Icons.payments_rounded,
      };
}