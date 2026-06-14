import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/inventory_item.dart';
import 'screens/auth_screen.dart';
import 'screens/setup_wizard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadSettings();
  runApp(const IntelligentRetailApp());
}

Future<void> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  globalSettings.businessName = prefs.getString('businessName') ?? '';
  globalSettings.businessType = prefs.getString('businessType') ?? '';
  globalSettings.currency = prefs.getString('currency') ?? 'KES';
  globalSettings.setupComplete = prefs.getBool('setupComplete') ?? false;
}

class IntelligentRetailApp extends StatelessWidget {
  const IntelligentRetailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retail Analytics Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF22C55E),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: const CardThemeData(color: Color(0xFF1E293B)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF22C55E)),
          ),
        ),
      ),
      home: globalSettings.setupComplete
          ? const AuthScreen()
          : const SetupWizardScreen(),
    );
  }
}
