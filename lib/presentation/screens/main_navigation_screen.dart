import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/vault_item.dart';
import '../state/vault_state.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'generator/generator_screen.dart';
import 'security_dashboard/security_dashboard_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onNavigateTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onSelectCategory(VaultItemType category) {
    context.read<VaultState>().setCategoryFilter(category);
    setState(() {
      _currentIndex = 1; // Switch to Search tab with category filter
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final screens = [
      HomeScreen(
        onNavigateTab: _onNavigateTab,
        onSelectCategory: _onSelectCategory,
      ),
      const SearchScreen(),
      const GeneratorScreen(),
      const SecurityDashboardScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavigateTab,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: theme.colorScheme.primary.withAlpha(30),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Generator',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety_rounded),
            label: 'Security',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
