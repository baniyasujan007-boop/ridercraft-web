import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_chip.dart';
import '../../../widgets/section_header.dart';

/// Horizontal scrollable category chips built from the actual product `tag`
/// values returned by the API. Tapping a category jumps to the Shop tab.
class CategoryChips extends StatelessWidget {
  final List<String> tags;
  final VoidCallback onCategoryTap;

  const CategoryChips({
    super.key,
    required this.tags,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Categories', showDivider: false),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 28 + 16 * MediaQuery.textScalerOf(context).scale(1.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: tags.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final tag = tags[index];
              return RcChip(
                label: tag,
                selected: false,
                icon: Icons.chevron_right_rounded,
                onTap: onCategoryTap,
              );
            },
          ),
        ),
      ],
    );
  }
}
