import 'package:flutter/material.dart';

import '../../../routes/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/press_scale.dart';

/// Quick action tiles on the Home screen styled like the website's category
/// and action cards: white cards with an icon tile on the dark wrapper.
class QuickActions extends StatelessWidget {
  final void Function(int index) onNavigateTab;

  const QuickActions({super.key, required this.onNavigateTab});

  void _open(BuildContext context, int tabIndex) {
    onNavigateTab(tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(
        label: 'Book Service',
        icon: Icons.build_rounded,
        color: AppColors.primaryDark,
        onTap: () => _open(context, 1),
      ),
      _Action(
        label: 'My Bike',
        icon: Icons.sports_motorsports_rounded,
        color: const Color(0xFF2563EB),
        onTap: () => Navigator.of(context).pushNamed(RouteNames.myBikes),
      ),
      _Action(
        label: 'Shop',
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFF16A34A),
        onTap: () => _open(context, 2),
      ),
      _Action(
        label: 'My Bookings',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF7C3AED),
        onTap: () => _open(context, 3),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.6,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) => actions[index],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _Action({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E4E9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A111827),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7F8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE4E8EE)),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF17202D),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF8B95A5),
            ),
          ],
        ),
      ),
    );
  }
}