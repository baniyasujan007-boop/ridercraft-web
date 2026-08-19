import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../providers/bike_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/error_view.dart';
import '../../widgets/rc_entrance.dart';
import 'widgets/bike_dashboard_card.dart';
import 'widgets/bike_form_sheet.dart';
import 'widgets/bike_selector.dart';
import 'widgets/delete_bike_sheet.dart';
import 'widgets/empty_garage.dart';
import 'widgets/garage_skeleton.dart';

/// My Garage — the rider's personal motorcycle command centre.
///
/// Dashboard of stored bikes (local storage only — the backend has no Bike
/// endpoints), a horizontal selector when there is more than one, a premium
/// active-bike card and the existing add / edit / remove / select flows.
class MyBikesScreen extends StatefulWidget {
  const MyBikesScreen({super.key});

  @override
  State<MyBikesScreen> createState() => _MyBikesScreenState();
}

class _MyBikesScreenState extends State<MyBikesScreen> {
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _ensureLoaded();
  }

  Future<void> _ensureLoaded() async {
    try {
      final provider = context.read<BikeProvider>();
      if (!provider.loaded) await provider.load();
      if (mounted) setState(() => _loadFailed = false);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    _ensureLoaded();
  }

  Future<void> _openAddSheet() async {
    await showBikeFormSheet(context);
  }

  Future<void> _openEditSheet(Bike bike) async {
    await showBikeFormSheet(context, bike: bike);
  }

  Future<void> _confirmDelete(Bike bike) async {
    final confirmed = await showDeleteBikeSheet(context, bike);
    if (confirmed != true || !mounted) return;
    try {
      await context.read<BikeProvider>().deleteBike(bike.id);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove the bike. Please try again.'),
        ),
      );
    }
  }

  void _openDetail(Bike bike) {
    Navigator.of(context).pushNamed(RouteNames.bikeDetail, arguments: bike.id);
  }

  @override
  Widget build(BuildContext context) {
    final bikesProvider = context.watch<BikeProvider>();
    final bikes = bikesProvider.bikes;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Bike'),
            ),
      body: _loading
          ? const GarageSkeleton()
          : _loadFailed
              ? ErrorView(
                  message: 'Could not load your garage.',
                  onRetry: _retry,
                )
              : bikes.isEmpty
                  ? EmptyGarage(onAdd: _openAddSheet)
                  : _GarageDashboard(
                      bikes: bikes,
                      selectedBike: bikesProvider.selectedBike,
                      onSelect: (bike) => bikesProvider.selectBike(bike.id),
                      onAdd: _openAddSheet,
                      onViewDetails: _openDetail,
                      onEdit: _openEditSheet,
                      onDelete: _confirmDelete,
                    ),
    );
  }
}

class _GarageDashboard extends StatelessWidget {
  final List<Bike> bikes;
  final Bike? selectedBike;
  final ValueChanged<Bike> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Bike> onViewDetails;
  final ValueChanged<Bike> onEdit;
  final ValueChanged<Bike> onDelete;

  const _GarageDashboard({
    required this.bikes,
    required this.selectedBike,
    required this.onSelect,
    required this.onAdd,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedBike ?? bikes.first;
    final showBack = Navigator.of(context).canPop();

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        _GarageHeader(showBack: showBack),
        if (bikes.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          BikeSelector(
            bikes: bikes,
            selectedBike: selectedBike,
            onSelect: onSelect,
            onAdd: onAdd,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: RcEntrance(
            child: BikeDashboardCard(
              bike: selected,
              selected: true,
              onViewDetails: () => onViewDetails(selected),
              onEdit: () => onEdit(selected),
              onDelete: () => onDelete(selected),
            ),
          ),
        ),
      ],
    );
  }
}

class _GarageHeader extends StatelessWidget {
  final bool showBack;

  const _GarageHeader({required this.showBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MY GARAGE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Manage your rides',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
