import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Round icon button with optional count badge / status dot and press
/// feedback. Used in the premium header for notifications, cart and profile.
class RcIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  /// When > 0 a numeric badge is shown (e.g. cart count).
  final int badgeCount;

  /// When true a small red dot is shown (e.g. unread notifications).
  final bool showDot;

  const RcIconButton({
    super.key,
    required this.icon,
    this.onTap,
    required this.tooltip,
    this.badgeCount = 0,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.surfaceAlt,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 21, color: AppColors.textPrimary),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Tooltip(message: tooltip, child: button),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              constraints: const BoxConstraints(minWidth: 17),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          )
        else if (showDot)
          Positioned(
            right: 1,
            top: 1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}