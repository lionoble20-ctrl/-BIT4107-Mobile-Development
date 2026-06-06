import 'package:flutter/material.dart';

void main() {
  runApp(const StudentManagementApp());
}

class StudentManagementApp extends StatelessWidget {
  const StudentManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Management Portal',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const RegistrationScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 80, color: Colors.teal),
                const SizedBox(height: 16),
                const Text('Portal Authentication',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Student Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock)),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Authenticate',
                    style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regNumController = TextEditingController();
  final _courseController = TextEditingController();
  final List<Map<String, String>> _studentDatabase = [];

  void _saveStudentRecord() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _studentDatabase.add({
          'name': _nameController.text.trim(),
          'regNum': _regNumController.text.trim(),
          'course': _courseController.text.trim(),
        });
      });
      _nameController.clear();
      _regNumController.clear();
      _courseController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record committed successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registry System'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginScreen())),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'Field required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regNumController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    prefixIcon: Icon(Icons.badge)),
                  validator: (v) => v!.isEmpty ? 'Field required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(
                    labelText: 'Course of Study',
                    prefixIcon: Icon(Icons.book)),
                  validator: (v) => v!.isEmpty ? 'Field required' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _saveStudentRecord,
                  icon: const Icon(Icons.save),
                  label: const Text('Commit Record To Local Storage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size.fromHeight(48)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('Persisted Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.teal),
            Expanded(
              child: _studentDatabase.isEmpty
                ? const Center(child: Text('No active records found in memory.'))
                : ListView.builder(
                    itemCount: _studentDatabase.length,
                    itemBuilder: (context, index) {
                      final student = _studentDatabase[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(student['name']!),
                          subtitle: Text(
                            '${student['course']} | ${student['regNum']}'),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}