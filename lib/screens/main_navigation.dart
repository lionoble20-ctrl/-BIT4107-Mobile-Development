import 'package:flutter/material.dart';
import 'package:retailapp/api_config.dart';
import 'auth_screen.dart';
import 'catalog_screen.dart';
import 'inventory_form.dart';
import 'analytics_dashboard.dart';
import 'advisory_screen.dart';
import 'currency_screen.dart';
import 'profile_screen.dart';

class MainNavigationContainer extends StatefulWidget {
  // Explicitly capture the authenticated database map from the login pipeline
  final Map<String, dynamic> authenticatedUser;

  const MainNavigationContainer({super.key, required this.authenticatedUser});

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
    CurrencyScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Force global session variable matching before rendering viewport downstream elements
    currentUserSession = widget.authenticatedUser;
  }

  // Systemic session wipe and route eviction routine
  void _handleSignOut() {
    setState(() {
      currentUserSession = null; // Purge runtime state instance records
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) =>
          false, // Flush full history stack to prevent unauthenticated back navigation
    );
  }

  void _handleOpenProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Structural Global Command Bar for Session Oversight
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user,
                        color: Color(0xFF22C55E),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OPERATOR: ${currentUserSession?['fullName']?.toUpperCase() ?? 'UNVERIFIED'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _handleOpenProfile,
                        icon: const Icon(
                          Icons.account_circle,
                          color: Colors.white70,
                          size: 20,
                        ),
                        tooltip: 'Profile',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _handleSignOut,
                        icon: const Icon(Icons.logout, size: 14),
                        label: const Text(
                          'LOGOUT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Primary Application View Window
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: 'Rates',
          ),
        ],
      ),
    );
  }
}
