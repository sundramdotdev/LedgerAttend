import 'package:flutter/material.dart';
import 'package:ledger_attend/data/services/auth_service.dart';
import 'package:ledger_attend/presentation/screens/signup_screen.dart';
import 'package:ledger_attend/presentation/screens/student_home_screen.dart';
import 'package:ledger_attend/presentation/screens/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginUser() async {
    setState(() {
      _isLoading = true;
    });

    String res = await _authService.loginUser(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (res == "success") {
       // Fetch role and navigate
       try{
           String role = await _authService.getUserRole();
           if(mounted){
              setState(() {
                _isLoading = false;
              });
              
             if (role == 'admin') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AdminDashboard()),
                );
              } else {
                 Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
                );
              }
           }
       } catch(e) {
            if(mounted){
               setState(() {
                  _isLoading = false;
               });
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching role: $e")));
            }
       }

    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
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
                    'LedgerAttend Login',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                   ),
                  const SizedBox(height: 64),
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
                  InkWell(
                    onTap: _loginUser,
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
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : const Text(
                              'Log in',
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
                            builder: (context) => const SignUpScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text(
                            "Sign up.",
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
