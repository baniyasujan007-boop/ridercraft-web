import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/press_scale.dart';

/// RiderCraft-branded "Continue with Google" button (elevated surface, white
/// Google mark) wired to the existing [AuthProvider.loginWithGoogle] flow. The
/// button never sees the Google configuration — it only invokes the flow.
class GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const GoogleButton({super.key, required this.loading, this.onPressed});

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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadow.soft,
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // The Google mark is a brand graphic, so it stays at a
                      // fixed size instead of scaling with text settings.
                      MediaQuery.withNoTextScaling(child: const _GoogleG()),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          'Continue with Google',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The classic four-colour Google "G" mark drawn with coloured text spans.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'G', style: TextStyle(color: blue)),
          TextSpan(text: 'o', style: TextStyle(color: red)),
          TextSpan(text: 'o', style: TextStyle(color: yellow)),
          TextSpan(text: 'g', style: TextStyle(color: blue)),
          TextSpan(text: 'l', style: TextStyle(color: green)),
          TextSpan(text: 'e', style: TextStyle(color: red)),
        ],
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
    );
  }
}