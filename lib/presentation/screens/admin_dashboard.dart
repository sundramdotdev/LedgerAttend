import 'package:flutter/material.dart';
import 'package:ledger_attend/data/services/auth_service.dart';
import 'package:ledger_attend/presentation/screens/login_screen.dart';
import 'package:ledger_attend/presentation/screens/event_list_screen.dart'; // Import added

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Your Event',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    icon: Icons.add_location_alt,
                    title: 'Create Event',
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.pushNamed(context, '/create-event');
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.person_add,
                    title: 'Add Member',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pushNamed(context, '/add-member');
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.list_alt,
                    title: 'Member List',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pushNamed(context, '/member-list');
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.qr_code_scanner,
                    title: 'Scan Attendance',
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to Scan Screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Scan Screen Coming Soon')),
                      );
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.date_range,
                    title: 'All Events',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EventListScreen()),
                      );
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.assignment,
                    title: 'Ledger',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pushNamed(context, '/admin-reports');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.7),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
