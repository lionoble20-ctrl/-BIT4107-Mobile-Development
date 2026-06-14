import 'package:flutter/material.dart';
import 'catalog_screen.dart';
import 'inventory_form.dart';
import 'analytics_dashboard.dart';
import 'advisory_screen.dart';

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CatalogScreen(),
    InventoryFormScreen(),
    AnalyticsDashboardScreen(),
    PredictiveAdvisoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF22C55E),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1E293B),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Stock Entry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'P&L Ledger',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Advisory Eng.',
          ),
        ],
      ),
    );
  }
}
