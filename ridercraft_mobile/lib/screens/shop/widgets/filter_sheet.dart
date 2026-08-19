import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/press_scale.dart';
import '../../../widgets/rc_button.dart';

/// Result of the shop filter/sort sheet.
class ShopFilters {
  final String sort;
  final bool inStockOnly;

  const ShopFilters({required this.sort, required this.inStockOnly});
}

/// Sort modes available in the Shop. Client-side presentation over the
/// already-loaded catalogue — the backend is untouched.
const List<({String key, String label})> kShopSortOptions = [
  (key: 'relevance', label: 'Relevance'),
  (key: 'price_asc', label: 'Price: Low to High'),
  (key: 'price_desc', label: 'Price: High to Low'),
  (key: 'rating', label: 'Top Rated'),
  (key: 'discount', label: 'Biggest Discount'),
];

String shopSortLabel(String key) {
  for (final option in kShopSortOptions) {
    if (option.key == key) return option.label;
  }
  return 'Relevance';
}

/// Bottom sheet that lets the rider filter (in-stock only) and sort the Shop
/// grid before closing with [ShopFilters]. Reset restores defaults immediately.
class FilterSheet extends StatefulWidget {
  final String sort;
  final bool inStockOnly;

  const FilterSheet({
    super.key,
    required this.sort,
    required this.inStockOnly,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String _sort;
  late bool _inStockOnly;

  @override
  void initState() {
    super.initState();
    _sort = widget.sort;
    _inStockOnly = widget.inStockOnly;
  }

  void _reset() {
    setState(() {
      _sort = 'relevance';
      _inStockOnly = false;
    });
  }

  void _done() {
    Navigator.of(context).pop(
      ShopFilters(sort: _sort, inStockOnly: _inStockOnly),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter & Sort',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
              const Divider(height: 24),
              _SectionLabel('Availability'),
              const SizedBox(height: 4),
              _AvailabilityToggle(
                value: _inStockOnly,
                onChanged: (value) => setState(() => _inStockOnly = value),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Sort by'),
              const SizedBox(height: 4),
              for (final option in kShopSortOptions) ...[
                _SortOptionTile(
                  label: option.label,
                  selected: _sort == option.key,
                  onTap: () => setState(() => _sort = option.key),
                ),
                const SizedBox(height: 2),
              ],
              const SizedBox(height: 18),
              RcButton(
                label: 'Show results',
                icon: Icons.check_rounded,
                onPressed: _done,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AvailabilityToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: value ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified_rounded,
              size: 18,
              color: value ? AppColors.success : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text(
                'In stock only',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 22,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 19,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}