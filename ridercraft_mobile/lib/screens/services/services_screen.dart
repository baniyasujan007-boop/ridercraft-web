import 'package:flutter/material.dart';

import '../../../models/service_package.dart';
import '../../../routes/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_card.dart';
import '../../../widgets/rc_entrance.dart';
import '../../../widgets/section_header.dart';
import '../main_scaffold.dart';
import 'widgets/shared_widgets.dart';
import 'widgets/service_package_card.dart';

/// Services tab — the three backend-supported service packages.
///
/// Browsing is open to guests. Booking requires sign-in; a guest who taps
/// Book Now is sent to login and returned to the booking flow afterwards.
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  static const List<String> _categories = ['All', 'Maintenance', 'Repair', 'Premium'];

  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  List<ServicePackage> get _filteredPackages {
    if (_selectedCategory == 'All') return servicePackages;
    // Map categories to package types
    final typeMap = {'Maintenance': 'basic', 'Repair': 'full', 'Premium': 'premium'};
    final type = typeMap[_selectedCategory];
    if (type == null) return servicePackages;
    return servicePackages.where((p) => p.type == type).toList();
  }

  Future<void> _openServiceDetail(BuildContext context, ServicePackage package) async {
    Navigator.of(context).pushNamed(
      RouteNames.serviceDetail,
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
            tooltip: 'My Bookings',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => MainScaffold.switchToTab(3),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverToBoxAdapter(
            child: RcEntrance(child: _buildHeroHeader()),
          ),
          // Categories
          SliverToBoxAdapter(
            child: RcEntrance(offset: 18, child: _buildCategoryChips()),
          ),
          // Service packages
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            sliver: SliverList.separated(
              itemCount: _filteredPackages.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final package = _filteredPackages[index];
                return StaggeredEntrance(
                  index: index,
                  child: ServicePackageCard(
                    package: package,
                    onBookNow: () => _openServiceDetail(context, package),
                  ),
                );
              },
            ),
          ),
          if (_filteredPackages.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ServicesEmptyState(
                onExploreServices: () => setState(() => _selectedCategory = 'All'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            kicker: 'Bike Care',
            title: 'Keep your ride running at its best.',
          ),
          const SizedBox(height: AppSpacing.md),
          RcCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: const Icon(
                    Icons.build_outlined,
                    color: AppColors.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expert technicians',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pickup from your doorstep. Transparent pricing.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: _categories.map((category) {
          final selected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ServiceCategoryChip(
              label: category,
              selected: selected,
              onTap: () => setState(() => _selectedCategory = category),
            ),
          );
        }).toList(),
      ),
    );
  }
}