import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// RiderCraft brand logo — the actual website asset
/// (`client/src/assets/ridercraft-logo.png`, bundled as
/// `assets/images/ridercraft-logo.png`).
///
/// Renders the exact RiderCraft asset so the app matches the website
/// (dark navy tile with the brand mark). `size` is the tile side length;
/// the radius is proportional to the website header mark.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const AppLogo({
    super.key,
    this.size = 128,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: Image.asset(
            'assets/images/ridercraft-logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 12),
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