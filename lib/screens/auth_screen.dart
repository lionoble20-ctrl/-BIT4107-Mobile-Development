import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import 'main_navigation.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isMerchant = true;
  bool _obscure = true;

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
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      size: 48,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  globalSettings.businessName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  globalSettings.businessType,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Operator Identifier (Email)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Email required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Security Access Key',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 4 ? 'Minimum 4 characters' : null,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Access Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _isMerchant ? 'Merchant Console' : 'Client View',
                            style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isMerchant,
                        onChanged: (v) => setState(() => _isMerchant = v),
                        activeColor: const Color(0xFF22C55E),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationContainer(),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'AUTHORIZE ACCESS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Secure authentication powered by intelligent analytics',
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
