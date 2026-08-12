import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Website-style section heading: orange uppercase kicker, bold uppercase
/// title and an optional trailing "See All" link with a divider rule below
/// (see `.shop-section-kicker` / `.featured-head` in the website CSS).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? kicker;
  final VoidCallback? onSeeAll;
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.title,
    this.kicker,
    this.onSeeAll,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (kicker != null) ...[
                      Text(
                        kicker!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
        ],
      ],
    );
  }
}
