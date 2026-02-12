import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ledger_attend/data/services/auth_service.dart';
import 'package:ledger_attend/presentation/screens/login_screen.dart';
import 'package:ledger_attend/presentation/screens/student_map_screen.dart';
import 'package:ledger_attend/presentation/screens/student_history_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLocationIntegrity();
  }

  Future<void> _checkLocationIntegrity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
           if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
           setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
         setState(() => _isLoading = false);
        return;
      }

      // Check for Mock Location
      Position position = await Geolocator.getCurrentPosition();
      if (position.isMocked) {
         if(mounted) {
           showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("Security Alert"),
              content: const Text("Mock location detected! You cannot use this app with a fake GPS."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
              ],
            ),
          );
         }
      }

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error checking location: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome, Student!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text("Scan QR codes or check map for attendance."),
                  const SizedBox(height: 30),
                  // Navigation to Map
                  SizedBox(
                    width: 250,
                    child: ElevatedButton.icon(
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StudentMapScreen()),
                           );
                        },
                        icon: const Icon(Icons.map),
                        label: const Text("Mark Attendance (Map)")
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Navigation to History
                  SizedBox(
                    width: 250,
                    child: OutlinedButton.icon(
                      onPressed: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StudentHistoryScreen()),
                         );
                      }, 
                      icon: const Icon(Icons.history), 
                      label: const Text("View History")
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
