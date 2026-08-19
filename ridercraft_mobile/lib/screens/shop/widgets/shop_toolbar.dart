import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/press_scale.dart';

/// Sort/filter toolbar for the Shop tab: a compact Filter pill, a Sort pill
/// showing the active mode, and the current result count. A pill highlights in
/// RiderCraft Red whenever an active selection deviates from the default.
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
      child: Row(
        children: [
          _ToolbarPill(
            label: 'Filter',
            icon: Icons.tune_rounded,
            active: filterActive,
            onTap: onFilter,
          ),
          const SizedBox(width: AppSpacing.sm),
          _ToolbarPill(
            label: 'Sort: $sortLabel',
            icon: Icons.swap_vert_rounded,
            active: sortLabel != 'Relevance',
            onTap: onSort,
          ),
          const Spacer(),
          if (countLabel != null)
            Text(
              countLabel!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolbarPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToolbarPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
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
              color: active
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}