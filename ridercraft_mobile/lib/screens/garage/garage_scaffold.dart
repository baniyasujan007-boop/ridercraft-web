import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'garage_bookings_screen.dart';
import 'garage_dashboard_screen.dart';
import 'garage_profile_screen.dart';

/// Garage Partner shell with three tabs: Dashboard, Bookings, Profile.
///
/// Rendered only for `role == "garage"` accounts. There is deliberately no
/// Shop / Cart / customer Bookings / My Garage here — those belong to the
/// customer app and remain untouched.
class GarageScaffold extends StatefulWidget {
  const GarageScaffold({super.key});

  /// Shared tab index so pushed flows can switch the garage shell's tab.
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  /// Programmatically switch to a tab (0 = Dashboard, 1 = Bookings).
  static void switchToTab(int index) => tabIndex.value = index;

  @override
  State<GarageScaffold> createState() => _GarageScaffoldState();
}

class _GarageScaffoldState extends State<GarageScaffold> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    GarageScaffold.tabIndex.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    GarageScaffold.tabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() => _selectedIndex = GarageScaffold.tabIndex.value);
  }

  void _selectTab(int index) {
    GarageScaffold.tabIndex.value = index;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const GarageDashboardScreen(),
      const GarageBookingsScreen(),
      const GarageProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note_rounded),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}