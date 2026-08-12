import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_package.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/section_header.dart';
import '../main_scaffold.dart';
import 'widgets/service_package_card.dart';

/// Services tab — the three backend-supported service packages.
///
/// Browsing is open to guests. Booking requires sign-in; a guest who taps
/// Book Now is sent to login and returned to the booking flow afterwards.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  Future<void> _startBooking(BuildContext context, ServicePackage package) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.of(context).pushNamed(RouteNames.login);
      if (!context.mounted) return;
      if (!context.read<AuthProvider>().isAuthenticated) return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pushNamed(
      RouteNames.serviceBooking,
      arguments: package,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            tooltip: 'My bookings',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => MainScaffold.switchToTab(3),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Choose your service', kicker: 'Bike Servicing'),
            const SizedBox(height: 14),
            const Text(
              'Pick a package and we will arrange pickup from your address. '
              'The exact price is confirmed by RiderCraft during booking.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            for (final package in servicePackages) ...[
              ServicePackageCard(
                package: package,
                onBookNow: () => _startBooking(context, package),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
