import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../models/inventory_item.dart'; // removed: unused
import 'auth_screen.dart';
import 'package:retailapp/api_config.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _selectedType = 'Retail Shop';
  String _selectedCurrency = 'KES';

  final List<String> _businessTypes = [
    'Retail Shop',
    'Electronics Shop',
    'Clothing Store',
    'Restaurant / Eatery',
    'Pharmacy',
    'Hardware Store',
    'Grocery Store',
    'Agricultural Supplies',
    'Wholesale',
    'Salon / Beauty',
    'Bookshop / Stationery',
    'Other',
  ];

  final List<String> _currencies = [
    'KES',
    'USD',
    'EUR',
    'GBP',
    'UGX',
    'TZS',
    'NGN',
    'ZAR',
  ];

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('businessName', _nameCtrl.text.trim());
    await prefs.setString('businessType', _selectedType);
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setBool('setupComplete', true);

    globalSettings.businessName = _nameCtrl.text.trim();
    globalSettings.businessType = _selectedType;
    globalSettings.currency = _selectedCurrency;
    globalSettings.setupComplete = true;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.analytics_rounded,
                  size: 80,
                  color: Color(0xFF22C55E),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to\nRetail Analytics Engine',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set up your business profile to get started.\nWorks for any type of retail business.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Business Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Kamau Electronics, Mama Njeri Shop',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter your business name'
                      : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Business Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  dropdownColor: const Color(0xFF1E293B),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _businessTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Currency',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  dropdownColor: const Color(0xFF1E293B),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCurrency = v!),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _completeSetup,
                  child: const Text(
                    'GET STARTED',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your data stays on your device.\nNo internet required to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
