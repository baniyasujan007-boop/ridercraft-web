import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/press_scale.dart';

/// Sort/filter toolbar for the Shop tab: a compact Filter pill, a Sort pill
/// showing the active mode, and the current result count. A pill highlights in
/// RiderCraft Red whenever an active selection deviates from the default.
///
/// The toolbar is a [Wrap] whose children are each width-capped and
/// ellipsized. At normal widths everything sits on a single row with the count
/// pushed to the right edge; at narrow widths or large text scales the pills
/// flow onto additional lines instead of overflowing.
class ShopToolbar extends StatelessWidget {
  final String sortLabel;
  final bool filterActive;
  final String? countLabel;
  final VoidCallback onFilter;
  final VoidCallback onSort;

  const ShopToolbar({
    super.key,
    required this.sortLabel,
    required this.filterActive,
    required this.onFilter,
    required this.onSort,
    this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxItemWidth = constraints.maxWidth;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ToolbarPill(
                label: 'Filter',
                icon: Icons.tune_rounded,
                active: filterActive,
                onTap: onFilter,
                maxWidth: maxItemWidth,
              ),
              _ToolbarPill(
                label: 'Sort: $sortLabel',
                icon: Icons.swap_vert_rounded,
                active: sortLabel != 'Relevance',
                onTap: onSort,
                maxWidth: maxItemWidth,
              ),
              if (countLabel != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxItemWidth),
                  child: Text(
                    countLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ToolbarPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  /// Upper bound on the pill width (the toolbar line width). The pill stays at
  /// its natural size until it would exceed this bound, at which point the
  /// label ellipsizes so the pill never overflows a line.
  final double maxWidth;

  const _ToolbarPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}