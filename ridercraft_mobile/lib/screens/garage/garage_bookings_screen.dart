import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/garage_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/error_view.dart';
import '../../widgets/rc_chip.dart';
import '../../widgets/rc_entrance.dart';
import 'widgets/garage_booking_card.dart';
import 'widgets/garage_loading_states.dart';

/// Garage Partner bookings tab: every assigned request with a status filter
/// (All / Requested / Confirmed / In Progress / Completed / Cancelled).
/// Filtering is client-side over the already-loaded backend data only.
class GarageBookingsScreen extends StatefulWidget {
  const GarageBookingsScreen({super.key});

  @override
  State<GarageBookingsScreen> createState() => _GarageBookingsScreenState();
}

class _GarageBookingsScreenState extends State<GarageBookingsScreen> {
  String _filter = 'all';

  static const _filters = [
    (value: 'all', label: 'All'),
    (value: 'requested', label: 'Requested'),
    (value: 'confirmed', label: 'Confirmed'),
    (value: 'in_progress', label: 'In Progress'),
    (value: 'completed', label: 'Completed'),
    (value: 'cancelled', label: 'Cancelled'),
  ];

  Future<void> _refresh() =>
      context.read<GarageProvider>().loadBookings(refresh: true);

  void _openDetail(String id) {
    Navigator.of(context).pushNamed(
      RouteNames.garageBookingDetail,
      arguments: id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<GarageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garage Bookings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: garage.loading ? null : _refresh,
          ),
        ],
      ),
      body: _buildBody(garage),
    );
  }

  Widget _buildBody(GarageProvider garage) {
    if (garage.loading && garage.bookings.isEmpty) {
      return const GarageBookingsSkeleton();
    }

    if (garage.error != null && garage.bookings.isEmpty) {
      return ErrorView(message: garage.error!, onRetry: _refresh);
    }

    final all = garage.bookings;
    if (all.isEmpty) {
      return _emptyState();
    }

    final filtered = _filter == 'all'
        ? all
        : all.where((b) => b.status == _filter).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _filters.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    RcChip(
                      label: _filters[i].label,
                      selected: _filter == _filters[i].value,
                      onTap: () => setState(
                        () => _filter = _filters[i].value,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No bookings with this status.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final booking = filtered[index];
                  return RcEntrance(
                    offset: 14,
                    child: GarageBookingCard(
                      booking: booking,
                      onTap: () => _openDetail(booking.id),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_available_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No bookings assigned yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'When riders near you request a service, the bookings land here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}