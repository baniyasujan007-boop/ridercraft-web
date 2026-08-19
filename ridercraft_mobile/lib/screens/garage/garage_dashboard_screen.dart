import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garage_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/error_view.dart';
import '../../widgets/rc_card.dart';
import '../../widgets/rc_entrance.dart';
import '../../widgets/section_header.dart';
import 'widgets/garage_booking_card.dart';
import 'widgets/garage_loading_states.dart';

/// Garage Partner dashboard — premium service-centre home fed entirely by
/// `GET /service-requests/garage` and the profile's `garageProfile`.
///
/// Header + availability (from `isAvailable`), summary counts derived from
/// the loaded bookings, and a recent/priority booking list (emergencies
/// first). No fabricated metrics.
class GarageDashboardScreen extends StatefulWidget {
  const GarageDashboardScreen({super.key});

  @override
  State<GarageDashboardScreen> createState() => _GarageDashboardScreenState();
}

class _GarageDashboardScreenState extends State<GarageDashboardScreen> {
  bool _loadedForSession = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && !_loadedForSession) {
      _loadedForSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<GarageProvider>().loadBookings();
      });
    }
    if (!auth.isAuthenticated) {
      _loadedForSession = false;
    }
  }

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
    final auth = context.watch<AuthProvider>();
    final garage = context.watch<GarageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garage Partner'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: garage.loading ? null : _refresh,
          ),
        ],
      ),
      body: _buildBody(garage, auth.user),
    );
  }

  Widget _buildBody(GarageProvider garage, User? user) {
    if (garage.loading && garage.bookings.isEmpty) {
      return const GarageDashboardSkeleton();
    }

    if (garage.error != null && garage.bookings.isEmpty) {
      return ErrorView(message: garage.error!, onRetry: _refresh);
    }

    final bookings = garage.bookings;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          RcEntrance(
            child: _GaragePartnerHeader(user: user),
          ),
          const SizedBox(height: AppSpacing.lg),
          RcEntrance(
            child: _SummaryRow(garage: garage),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(
            kicker: 'Operations',
            title: 'Recent & Priority',
          ),
          const SizedBox(height: AppSpacing.md),
          if (bookings.isEmpty)
            const _NoBookingsState()
          else
            ..._recentList(garage),
        ],
      ),
    );
  }

  List<Widget> _recentList(GarageProvider garage) {
    final recent = garage.recentBookings.take(4).toList();
    return [
      for (var i = 0; i < recent.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: RcEntrance(
            // Staggered entrance for the booking cards.
            offset: 14,
            child: GarageBookingCard(
              booking: recent[i],
              onTap: () => _openDetail(recent[i].id),
            ),
          ),
        ),
    ];
  }
}

/// Brand header with the garage name and a live availability pill.
class _GaragePartnerHeader extends StatelessWidget {
  final User? user;

  const _GaragePartnerHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final profile = user?.garageProfile;
    final garageName = profile?.garageName.isNotEmpty ?? false
        ? profile!.garageName
        : (user?.name.isNotEmpty ?? false ? user!.name : 'Your Garage');
    final available = profile?.isAvailable ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3646), Color(0xFF141A22)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RIDERCRAFT GARAGE',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            garageName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AvailabilityPill(available: available),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  final bool available;

  const _AvailabilityPill({required this.available});

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              available ? 'AVAILABLE' : 'UNAVAILABLE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three derived-state summary cards: Pending, Active, Completed.
class _SummaryRow extends StatelessWidget {
  final GarageProvider garage;

  const _SummaryRow({required this.garage});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.schedule_rounded,
        color: AppColors.warning,
        label: 'Pending',
        value: garage.pendingCount,
      ),
      (
        icon: Icons.build_circle_outlined,
        color: AppColors.info,
        label: 'Active',
        value: garage.activeCount,
      ),
      (
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
        label: 'Completed',
        value: garage.completedCount,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: _SummaryCard(item: items[i])),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ({IconData icon, Color color, String label, int value}) item;

  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 19),
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${item.value}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoBookingsState extends StatelessWidget {
  const _NoBookingsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: RcCard(
        child: Column(
          children: [
            const Icon(
              Icons.event_available_outlined,
              size: 42,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No bookings assigned yet.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'New service requests from riders near you will appear here.',
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