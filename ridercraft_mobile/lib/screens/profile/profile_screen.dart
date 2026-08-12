import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

/// Profile tab placeholder. Profile info, My Bikes, Orders, Bookings,
/// Saved Products, Notifications and Settings come in the profile module.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user?.name ?? 'Rider',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, RouteNames.orders),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('My Orders'),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Logout',
              icon: Icons.logout_rounded,
              backgroundColor: AppColors.surfaceElevated,
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
