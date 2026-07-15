import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'models/inventory_item.dart';
import 'services/database_helper.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.init();

  // Load all data from SQLite database on startup
  globalInventory = await DatabaseHelper.instance.getAllProducts();
  globalSales = await DatabaseHelper.instance.getAllSales();

  // Load settings from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  globalSettings.businessName = prefs.getString('businessName') ?? '';
  globalSettings.businessType = prefs.getString('businessType') ?? '';
  globalSettings.currency = prefs.getString('currency') ?? 'KES';
  globalSettings.setupComplete = prefs.getBool('setupComplete') ?? false;

  // Load saved theme preference (defaults to dark, matching the app's
  // original look, if the user has never toggled it before).
  final savedIsDark = prefs.getBool('isDarkMode') ?? true;
  themeModeNotifier.value = savedIsDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const IntelligentRetailApp());
}

class IntelligentRetailApp extends StatelessWidget {
  const IntelligentRetailApp({super.key});

  static const _accentGreen = Color(0xFF22C55E);

  ThemeData get _darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: _accentGreen,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardTheme: const CardThemeData(color: Color(0xFF1E293B)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentGreen,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accentGreen),
      ),
    ),
  );

  ThemeData get _lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: _accentGreen,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    cardTheme: const CardThemeData(color: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.5,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentGreen,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accentGreen),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Retail Analytics Engine',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
