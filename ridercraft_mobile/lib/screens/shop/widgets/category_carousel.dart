import 'package:flutter/material.dart';

import '../../../widgets/rc_chip.dart';

/// Category rail for the Shop tab: an "All" chip followed by every product
/// tag present in the loaded catalogue. Tags are derived from real catalogue
/// data (no hardcoded categories), each with a relevant icon.
class CategoryCarousel extends StatelessWidget {
  final List<String> tags;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const CategoryCarousel({
    super.key,
    required this.tags,
    required this.selected,
    required this.onSelected,
  });

  static const Map<String, IconData> _tagIcons = {
    'Helmets': Icons.sports_motorsports_rounded,
    'Gloves': Icons.back_hand_outlined,
    'Jackets': Icons.checkroom_rounded,
    'Riding Gear': Icons.shield_outlined,
    'Boots': Icons.directions_walk_rounded,
    'Parts': Icons.settings_rounded,
    'Accessories': Icons.inventory_2_outlined,
    'Batteries': Icons.bolt_rounded,
    'Oil': Icons.water_drop_outlined,
    'Lubricants': Icons.water_drop_outlined,
    'Tires': Icons.radio_button_unchecked_rounded,
    'Security': Icons.lock_outline_rounded,
    'Chains': Icons.link_rounded,
    'Brakes': Icons.disc_full_rounded,
  };

  IconData _iconFor(String tag) =>
      _tagIcons[tag] ?? Icons.category_rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(
            label: 'All',
            icon: Icons.apps_rounded,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final tag in tags.toList()..sort())
            _chip(
              label: tag,
              icon: _iconFor(tag),
              selected: selected == tag,
              onTap: () => onSelected(tag),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: RcChip(
        label: label,
        icon: icon,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}