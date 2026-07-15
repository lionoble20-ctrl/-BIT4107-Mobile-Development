import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/validator_service.dart';
import '../services/event_logger_service.dart';
import 'package:retailapp/api_config.dart';

class AdminResetPasswordScreen extends StatefulWidget {
  const AdminResetPasswordScreen({super.key});

  @override
  State<AdminResetPasswordScreen> createState() =>
      _AdminResetPasswordScreenState();
}

class _AdminResetPasswordScreenState extends State<AdminResetPasswordScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DatabaseHelper.instance.getAllUsers();
    if (!mounted) return;
    setState(() {
      _allUsers = users;
      _isLoadingUsers = false;
    });
  }

  void _openResetDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => _ResetPasswordDialog(
        user: user,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Password reset for ${user['email']} — the operator should log in with the new password and change it if desired.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminEmail = currentUserSession?['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Operator Password'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoadingUsers
            ? const Center(child: CircularProgressIndicator())
            : _allUsers.isEmpty
            ? const Center(
                child: Text(
                  'No operator accounts found.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _allUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final user = _allUsers[i];
                  final email = user['email'] as String;
                  final isSelf = email == adminEmail;

                  return Card(
                    color: const Color(0xFF1E293B),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF22C55E),
                        child: Text(
                          (user['fullName'] as String? ?? '?').characters.first
                              .toUpperCase(),
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      title: Text(user['fullName'] ?? ''),
                      subtitle: Text(
                        '$email • ${user['role'] ?? ''}${isSelf ? ' (You)' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () => _openResetDialog(user),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSuccess;

  const _ResetPasswordDialog({required this.user, required this.onSuccess});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final newHash = _hashPassword(_passwordController.text);
    final success = await DatabaseHelper.instance.resetPassword(
      email: widget.user['email'] as String,
      newPasswordHash: newHash,
    );
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      EventLoggerService.log(
        'ADMIN',
        'Password reset by admin for ${widget.user['email']}',
      );
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reset password. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text('Reset password for\n${widget.user['fullName']}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => ValidatorService.validatePassword(v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              validator: (v) => ValidatorService.validatePasswordMatch(
                _passwordController.text,
                v ?? '',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Reset'),
        ),
      ],
    );
  }
}
