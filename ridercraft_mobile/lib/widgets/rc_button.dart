import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'press_scale.dart';

/// Primary RiderCraft CTA: RiderCraft Red gradient fill, rounded, with a soft
/// red glow and press feedback. Use for the primary action on a surface.
class RcButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  const RcButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !loading && onPressed != null;
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : IconTheme.merge(
            data: const IconThemeData(color: Colors.white, size: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ],
            ),
          );

    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: enabled ? AppShadow.redGlow : const [],
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          child: child,
        ),
      ),
    );

    final wrapped = PressScale(onTap: enabled ? onPressed : null, child: button);
    if (!fullWidth) return Center(child: wrapped);
    return wrapped;
  }
}

/// Secondary RiderCraft button: neutral elevated surface with a thin border.
/// Use next to a primary CTA or for less important actions.
class RcSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const RcSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onPressed,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.textSecondary, size: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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