import 'package:flutter/material.dart';

import '../../../services/api_exception.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';

/// Polished, accessible feedback for the auth screens. Error text always comes
/// from [ApiException.message] (the friendly, already-normalized copy) and
/// never surfaces raw server payloads, stack traces or tokens.
void showAuthSnack(
  BuildContext context, {
  required String message,
  bool isError = true,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? AppColors.surfaceElevated : AppColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(
          color: isError ? AppColors.error : AppColors.success,
          width: 1,
        ),
      ),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: isError ? AppColors.error : AppColors.success,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Derives a safe, user-friendly message from an auth failure, preserving the
/// existing [ApiException] copy that the backend already normalizes.
String authErrorMessage(Object error, {required String fallback}) {
  if (error is ApiException) return error.message;
  if (error is FlutterError) return fallback;
  final raw = error.toString().trim();
  return raw.isEmpty ? fallback : raw;
}