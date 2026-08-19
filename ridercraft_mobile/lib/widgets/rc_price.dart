import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Price display component: bold current price with an optional strikethrough
/// original price. Used inside product cards, carts and order summaries.
class RcPrice extends StatelessWidget {
  final String amount;
  final String? originalAmount;
  final double size;
  final Color color;

  const RcPrice({
    super.key,
    required this.amount,
    this.originalAmount,
    this.size = 18,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (originalAmount != null && originalAmount!.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              originalAmount!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: size * 0.68,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}