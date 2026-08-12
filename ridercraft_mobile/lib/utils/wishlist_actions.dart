import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../routes/route_names.dart';
import '../services/api_exception.dart';

/// Toggles wishlist state from any context, handling authentication:
/// - guests get a sign-in prompt (wishlist requires auth on the backend)
/// - auth failures prompt sign-in
/// - other failures show a snackbar
Future<void> toggleWishlistFromContext(
  BuildContext context,
  Product product,
) async {
  final auth = context.read<AuthProvider>();
  if (!auth.isAuthenticated) {
    await promptSignIn(context);
    return;
  }
  try {
    await context.read<ProductProvider>().toggleWishlist(product);
  } on ApiException catch (error) {
    if (!context.mounted) return;
    if (error.isUnauthorized) {
      await promptSignIn(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

/// Shows a sign-in prompt and navigates to login when accepted.
Future<void> promptSignIn(BuildContext context) async {
  final shouldLogin = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign in required'),
      content: const Text(
        'Sign in to save products and use RiderCraft features.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sign in'),
        ),
      ],
    ),
  );

  if (shouldLogin == true && context.mounted) {
    Navigator.of(context).pushNamed(RouteNames.login);
  }
}
