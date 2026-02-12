import 'package:flutter/material.dart';
import 'package:ledger_attend/data/services/auth_service.dart';
import 'package:ledger_attend/presentation/screens/login_screen.dart';
import 'package:ledger_attend/presentation/screens/student_home_screen.dart';
import 'package:ledger_attend/presentation/screens/admin_dashboard.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _role = 'student'; // Default role

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _signUpUser() async {
    setState(() {
      _isLoading = true;
    });

    String res = await _authService.signUpUser(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      role: _role,
    );

    if (res == "success") {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Navigate based on role
        if (_role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'LedgerAttend Sign Up',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 64),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your password',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _role,
                    items: ['student', 'admin'].map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _role = newValue!;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      labelText: "Select Role",
                    ),
                  ),

                  const SizedBox(height: 24),
                  InkWell(
                    onTap: _signUpUser,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        color: Colors.blue,
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign up',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Text("Don't have an account? "),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text(
                            "Login.",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
