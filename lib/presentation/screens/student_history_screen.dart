import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentHistoryScreen extends StatelessWidget {
  const StudentHistoryScreen({super.key});

  // Get current user email safely
  String? get _currentUserEmail {
    return FirebaseAuth.instance.currentUser?.email;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserEmail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Attendance")),
        body: const Center(child: Text("Please login to view history")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Attendance")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where(
              'email',
              isEqualTo: _currentUserEmail?.trim().toLowerCase(),
            ) // Normalize email
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No attendance records found."));
          }

          final records = snapshot.data!.docs;
          final int totalCount = records.length;

          return Column(
            children: [
              // Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Sessions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$totalCount",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // List of Records
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final data = records[index].data() as Map<String, dynamic>;

                    final String eventName =
                        data['eventName'] ?? 'Unknown Event';
                    final Timestamp? ts = data['timestamp'];
                    final String selfieUrl = data['selfieUrl'] ?? '';

                    final String dtStr = ts != null
                        ? DateFormat('MMM d, y • h:mm a').format(ts.toDate())
                        : 'Unknown Date';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            if (selfieUrl.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  child: Image.network(
                                    selfieUrl,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: selfieUrl.isNotEmpty
                                ? NetworkImage(selfieUrl)
                                : null,
                            child: selfieUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                        ),
                        title: Text(
                          eventName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(dtStr),
                        trailing: const Icon(
                          Icons.verified,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
