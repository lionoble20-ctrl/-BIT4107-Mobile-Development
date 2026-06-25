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

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Operator profile modifications saved successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Toggling the AppBar icon now does double duty: entering edit mode just
  // flips the flag, but exiting edit mode (tapping the checkmark) triggers
  // an actual save instead of silently discarding the typed changes.
  void _handleToggleEdit() {
    if (_isEditing) {
      _handleSaveChanges();
    } else {
      setState(() => _isEditing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserSession == null) {
      return const Scaffold(body: Center(child: Text('No operator signed in')));
    }

    final email = currentUserSession?['email'] ?? '';
    final role = currentUserSession?['role'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Profile'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _handleToggleEdit,
            icon: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_isEditing ? Icons.check : Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Read-only account identity card — email is the PRIMARY KEY
              // so it's never editable, but the user should still see
              // which account they're viewing.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 16,
                          color: Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          role,
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _businessController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSaveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
