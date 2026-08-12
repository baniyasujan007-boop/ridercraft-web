import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// RiderCraft brand mark used on the splash and auth screens.
///
/// The existing website logo lives in `client/src/assets/ridercraft-logo.png`;
/// a Flutter asset version can be dropped into `assets/` and rendered instead
/// of this vector mark. Until then a bold wordmark + chevron is used.
class AppLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;

  const AppLogo({
    super.key,
    this.fontSize = 32,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: fontSize * 1.5,
              height: fontSize * 1.5,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(fontSize * 0.4),
              ),
              child: Icon(
                Icons.sports_motorsports_rounded,
                color: Colors.white,
                size: fontSize,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'RiderCraft',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'RIDE SHARP. RIDE PREPARED.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}
