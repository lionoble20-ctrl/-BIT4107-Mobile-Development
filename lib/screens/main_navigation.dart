import 'dart:async';
import 'package:flutter/material.dart';
import 'package:retailapp/api_config.dart';
import '../models/inventory_item.dart';
import '../services/connectivity_service.dart';
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

  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySub;

  List<InventoryItem> _flaggedStockItems = [];
  Timer? _stockCheckTimer;

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

    _isOnline = ConnectivityService.instance.isOnline;
    _connectivitySub = ConnectivityService.instance.onStatusChange.listen((
      online,
    ) {
      if (mounted) setState(() => _isOnline = online);
    });

    _checkLowStock();
    _stockCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkLowStock(),
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _stockCheckTimer?.cancel();
    super.dispose();
  }

  void _checkLowStock() {
    final flagged = globalInventory
        .where((i) => i.isLowStock || i.isOutOfStock)
        .toList();
    if (mounted) setState(() => _flaggedStockItems = flagged);
  }

  String _buildLowStockMessage() {
    final outOfStock = _flaggedStockItems
        .where((i) => i.isOutOfStock)
        .map((i) => i.name)
        .toList();
    final lowStock = _flaggedStockItems
        .where((i) => i.isLowStock)
        .map((i) => i.name)
        .toList();

    if (outOfStock.isNotEmpty && lowStock.isNotEmpty) {
      return 'OUT OF STOCK: ${outOfStock.join(', ')}  •  Low: ${lowStock.join(', ')} — tap to restock';
    } else if (outOfStock.isNotEmpty) {
      return 'OUT OF STOCK: ${outOfStock.join(', ')} — tap to restock';
    } else {
      return 'Low stock: ${lowStock.join(', ')} — tap to restock';
    }
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
            if (!_isOnline)
              Container(
                width: double.infinity,
                color: const Color(0xFFB91C1C),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Text(
                  'Offline — showing cached data, changes will not sync',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_flaggedStockItems.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Container(
                  width: double.infinity,
                  color: _flaggedStockItems.any((i) => i.isOutOfStock)
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  child: Text(
                    _buildLowStockMessage(),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
