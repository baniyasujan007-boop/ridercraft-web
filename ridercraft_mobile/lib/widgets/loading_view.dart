import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Simple loading state with the brand accent.
class LoadingView extends StatelessWidget {
  final String? label;

  const LoadingView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(
              label!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
