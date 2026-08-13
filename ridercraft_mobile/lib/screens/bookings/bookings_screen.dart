import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../main_scaffold.dart';
import 'widgets/booking_card.dart';

/// Bookings tab — the rider's service bookings from `GET /service-requests/my`.
///
/// Requires authentication; guests see a sign-in prompt. Pull to refresh,
/// loading, empty and error states included.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool _loadedForSession = false;

  @override
  void initState() {
    super.initState();
    MainScaffold.tabIndex.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    MainScaffold.tabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (MainScaffold.tabIndex.value == 3 &&
        auth.isAuthenticated &&
        _loadedForSession) {
      context.read<BookingProvider>().loadBookings();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && !_loadedForSession) {
      _loadedForSession = true;
      // Deferred so the provider's synchronous notifyListeners does not run
      // during the build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<BookingProvider>().loadBookings();
      });
    }
    if (!auth.isAuthenticated) {
      _loadedForSession = false;
    }
  }

  Future<void> _refresh() =>
      context.read<BookingProvider>().loadBookings();

  void _openDetail(int index) {
    final booking = context.read<BookingProvider>().bookings[index];
    Navigator.of(context).pushNamed(
      RouteNames.bookingDetail,
      arguments: booking,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
            ),
        ],
      ),
      body: _buildBody(auth, bookingProvider),
    );
  }

  Widget _buildBody(AuthProvider auth, BookingProvider provider) {
    if (!auth.isAuthenticated) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to see your service bookings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(RouteNames.login),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.loading && provider.bookings.isEmpty) {
      return const LoadingView(label: 'Loading bookings…');
    }

    // Only replace the list with the error view when there is nothing to
    // show; a failed refresh while data exists keeps the stale list visible.
    if (provider.error != null && provider.bookings.isEmpty) {
      return ErrorView(message: provider.error!, onRetry: _refresh);
    }

    final bookings = provider.bookings;
    if (bookings.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'No service bookings yet.\n\nBook your first service with '
                'RiderCraft.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: 'Explore Services',
                icon: Icons.build_outlined,
                fullWidth: false,
                onPressed: () => MainScaffold.switchToTab(1),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingCard(
            booking: booking,
            onTap: () => _openDetail(index),
          );
        },
      ),
    );
  }
}
