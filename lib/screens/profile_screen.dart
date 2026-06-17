import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'package:retailapp/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _businessController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: currentUserSession?['fullName'] ?? '',
    );
    _businessController = TextEditingController(
      text: currentUserSession?['businessName'] ?? '',
    );
    _phoneController = TextEditingController(
      text: currentUserSession?['phone'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = currentUserSession?['email'] ?? '';
    final fullName = _nameController.text.trim();
    final businessName = _businessController.text.trim();
    final phone = _phoneController.text.trim();

    // Persist modifications to the active database layer
    await DatabaseHelper.instance.updateUser(
      email: email,
      fullName: fullName,
      businessName: businessName,
      phone: phone,
    );

    // Refresh the global runtime session mapping cache
    final updatedUser = await DatabaseHelper.instance.getUserByEmail(email);
    currentUserSession = updatedUser;

    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Operator profile modifications saved successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserSession == null) {
      return const Scaffold(body: Center(child: Text('No operator signed in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Profile'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(controller: _nameController),
                const SizedBox(height: 8),
                TextFormField(controller: _businessController),
                const SizedBox(height: 8),
                TextFormField(controller: _phoneController),
                const SizedBox(height: 16),
                if (_isEditing)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSaveChanges,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Save'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
