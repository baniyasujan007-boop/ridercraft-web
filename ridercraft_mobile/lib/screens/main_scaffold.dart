import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bookings/bookings_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'services/services_screen.dart';
import 'shop/shop_screen.dart';

/// App shell with the five-tab bottom navigation:
/// Home, Services, Shop, Bookings, Profile.
///
/// Exposes [switchToTab] so pushed flows (e.g. booking success) can land on a
/// specific tab after popping back to the shell.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  /// Shared tab index. Switched tabs rebuild while preserving tab state
  /// (IndexedStack).
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  /// Programmatically switch to a tab (0 = Home, 3 = Bookings).
  static void switchToTab(int index) => tabIndex.value = index;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

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
    setState(() => _selectedIndex = MainScaffold.tabIndex.value);
  }

  void _selectTab(int index) {
    MainScaffold.tabIndex.value = index;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(onNavigateTab: _selectTab),
      const ServicesScreen(),
      const ShopScreen(),
      const BookingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build_rounded),
              label: 'Services',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Shop',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
