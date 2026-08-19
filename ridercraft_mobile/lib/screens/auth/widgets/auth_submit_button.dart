import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/press_scale.dart';

/// Primary auth CTA: RiderCraft Red gradient fill, soft glow and a premium
/// loading state that keeps the label visible ("Signing you in...") next to a
/// small inline spinner. Duplicate submission is blocked while loading.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final String loadingLabel;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const AuthSubmitButton({
    super.key,
    required this.label,
    this.loadingLabel = 'Please wait...',
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !loading && onPressed != null;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 480),
        child: PressScale(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.large),
              boxShadow: enabled ? AppShadow.redGlow : const [],
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: enabled ? 1 : 0.75,
                ),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              child: loading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Flexible(child: Text(loadingLabel)),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null)
                          Icon(
                            icon,
                            size: 19,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        if (icon != null) const SizedBox(width: AppSpacing.sm),
                        Text(label),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}