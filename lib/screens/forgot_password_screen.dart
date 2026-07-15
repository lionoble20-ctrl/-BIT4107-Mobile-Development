import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/validator_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { enterEmail, answerQuestion, setNewPassword, done }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _Step _step = _Step.enterEmail;
  String? _securityQuestion;
  String _normalizedEmail = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _hashAnswer(String answer) {
    final normalized = answer.trim().toLowerCase();
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _lookupSecurityQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final question = await DatabaseHelper.instance.getSecurityQuestion(email);
    setState(() => _isLoading = false);

    if (question == null) {
      _showError(
        'No recovery question found for this account. '
        'Ask a Merchant admin to reset your password instead.',
      );
      return;
    }

    setState(() {
      _normalizedEmail = email;
      _securityQuestion = question;
      _step = _Step.answerQuestion;
    });
  }

  Future<void> _verifyAnswer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final answerHash = _hashAnswer(_answerController.text);
    final correct = await DatabaseHelper.instance.verifySecurityAnswer(
      _normalizedEmail,
      answerHash,
    );
    setState(() => _isLoading = false);

    if (!correct) {
      _showError('Incorrect answer. Please try again.');
      return;
    }

    setState(() => _step = _Step.setNewPassword);
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final newHash = _hashPassword(_newPasswordController.text);
    final success = await DatabaseHelper.instance.resetPassword(
      email: _normalizedEmail,
      newPasswordHash: newHash,
    );
    setState(() => _isLoading = false);

    if (!success) {
      _showError('Could not update password. Please try again.');
      return;
    }

    setState(() => _step = _Step.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recover Access'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(key: _formKey, child: _buildStepContent()),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _Step.enterEmail:
        return _EmailStep(
          controller: _emailController,
          isLoading: _isLoading,
          onSubmit: _lookupSecurityQuestion,
        );
      case _Step.answerQuestion:
        return _AnswerStep(
          question: _securityQuestion!,
          controller: _answerController,
          isLoading: _isLoading,
          onSubmit: _verifyAnswer,
        );
      case _Step.setNewPassword:
        return _NewPasswordStep(
          passwordController: _newPasswordController,
          confirmController: _confirmPasswordController,
          obscure: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          isLoading: _isLoading,
          onSubmit: _submitNewPassword,
        );
      case _Step.done:
        return _DoneStep(onBackToLogin: () => Navigator.pop(context));
    }
  }
}

class _EmailStep extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _EmailStep({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Forgot Password',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your registered email to begin identity verification.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Operator Identifier (Email)',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) => ValidatorService.validateEmail(v ?? ''),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text(
                  'CONTINUE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

class _AnswerStep extends StatelessWidget {
  final String question;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _AnswerStep({
    required this.question,
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verify Identity',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            question,
            style: const TextStyle(
              color: Color(0xFF22C55E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Your Answer',
            prefixIcon: Icon(Icons.question_answer_outlined),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Answer required' : null,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text(
                  'VERIFY',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

class _NewPasswordStep extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _NewPasswordStep({
    required this.passwordController,
    required this.confirmController,
    required this.obscure,
    required this.onToggleObscure,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Set New Password',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Identity verified. Choose a new security access key.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: passwordController,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: onToggleObscure,
            ),
          ),
          validator: (v) => ValidatorService.validatePassword(v ?? ''),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmController,
          obscureText: obscure,
          decoration: const InputDecoration(
            labelText: 'Confirm New Password',
            prefixIcon: Icon(Icons.lock_clock_outlined),
          ),
          validator: (v) => ValidatorService.validatePasswordMatch(
            passwordController.text,
            v ?? '',
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text(
                  'UPDATE PASSWORD',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  final VoidCallback onBackToLogin;

  const _DoneStep({required this.onBackToLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 64),
        const SizedBox(height: 16),
        const Text(
          'Password Updated',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'You can now log in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onBackToLogin,
          child: const Text(
            'BACK TO LOGIN',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
