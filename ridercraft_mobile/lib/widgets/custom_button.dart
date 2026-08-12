import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Primary CTA button with an inline loading spinner.
///
/// Matches the website's primary buttons: a 135deg orange gradient with a
/// soft glow. A solid [backgroundColor] overrides the gradient.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final IconData? icon;
  final Color? backgroundColor;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.fullWidth = true,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !loading && onPressed != null;
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label)),
            ],
          );

    final gradient = backgroundColor != null
        ? LinearGradient(colors: [backgroundColor!, backgroundColor!])
        : (enabled
            ? AppColors.primaryGradient
            : const LinearGradient(
                colors: [Color(0xFF4A3A2C), Color(0xFF45362B)],
              ));

    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: backgroundColor == null
            ? [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (!fullWidth) return Center(child: button);
    return button;
  }
}
