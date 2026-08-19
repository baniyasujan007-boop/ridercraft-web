import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Premium search field. The fill slides to the elevated surface and the
/// border tints RiderCraft Red while focused — a subtle, fast transition.
class RcSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String hint;

  const RcSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.hint = 'Search bikes, parts & accessories',
  });

  @override
  State<RcSearchBar> createState() => _RcSearchBarState();
}

class _RcSearchBarState extends State<RcSearchBar> {
  bool _focused = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: _focused ? AppColors.surfaceElevated : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(
            color: _focused ? AppColors.primary : AppColors.border,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: _focused ? AppShadow.card : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 21,
              color: _focused ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: widget.controller,
                onChanged: (value) {
                  setState(() => _query = value);
                  widget.onChanged(value);
                },
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  setState(() => _query = '');
                  widget.onChanged('');
                  widget.onClear?.call();
                },
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}