import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/validator_service.dart';
import '../services/input_handler_service.dart';
import '../services/event_logger_service.dart';

const List<String> kSecurityQuestions = [
  'What was the name of your first pet?',
  'What is your mother\'s maiden name?',
  'What city were you born in?',
  'What was the name of your first school?',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  String _selectedRole = 'Merchant';
  String _selectedSecurityQuestion = kSecurityQuestions.first;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  String _hashAnswer(String answer) {
    // Normalize so "Blue" and "blue " hash the same way
    final normalized = answer.trim().toLowerCase();
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    InputHandlerService.handleRegisterSubmit(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      onValid: () => _performRegister(email, password),
      onInvalid: (errors) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errors.values.first),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _performRegister(String email, String password) async {
    setState(() => _isLoading = true);

    final fullName = _nameController.text.trim();
    final passwordHash = _hashPassword(password);
    final securityAnswerHash = _hashAnswer(_securityAnswerController.text);

    final success = await DatabaseHelper.instance.insertUser(
      email: email,
      fullName: fullName,
      passwordHash: passwordHash,
      role: _selectedRole,
      securityQuestion: _selectedSecurityQuestion,
      securityAnswerHash: securityAnswerHash,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      EventLoggerService.log('REGISTER', 'New operator registered: $email');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operator registered successfully. Please log in.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Return to AuthScreen
    } else {
      EventLoggerService.log(
        'REGISTER',
        'Registration failed — email already exists: $email',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration Failed: Email identifier already exists.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Operator'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create New Account',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Initialize access credentials for system administration.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Full name required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Operator Identifier (Email)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => ValidatorService.validateEmail(val ?? ''),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'System Access Role',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Merchant',
                      child: Text('Merchant Console'),
                    ),
                    DropdownMenuItem(
                      value: 'Client',
                      child: Text('Client View'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Security Access Key (Password)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) =>
                      ValidatorService.validatePassword(val ?? ''),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Security Access Key',
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (val) => ValidatorService.validatePasswordMatch(
                    _passwordController.text,
                    val ?? '',
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Account Recovery',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Used to verify your identity if you forget your password.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSecurityQuestion,
                  decoration: const InputDecoration(
                    labelText: 'Security Question',
                    prefixIcon: Icon(Icons.help_outline),
                  ),
                  items: kSecurityQuestions
                      .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSecurityQuestion = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _securityAnswerController,
                  decoration: const InputDecoration(
                    labelText: 'Your Answer',
                    prefixIcon: Icon(Icons.question_answer_outlined),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Security answer required'
                      : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                          'SUBMIT REGISTRATION',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
