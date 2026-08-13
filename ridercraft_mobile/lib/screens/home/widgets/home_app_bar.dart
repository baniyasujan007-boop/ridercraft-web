import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Home app bar: RiderCraft branding on the left, notification and profile
/// actions on the right.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  const HomeAppBar({
    super.key,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderSubtle),
      ),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/images/ridercraft-logo.png',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'RiderCraft',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: onNotificationsTap,
          icon: const Icon(Icons.notifications_none_rounded, size: 26),
        ),
        IconButton(
          tooltip: 'Profile',
          onPressed: onProfileTap,
          icon: const Icon(Icons.account_circle_outlined, size: 26),
        ),
      ],
    );
  }
}
