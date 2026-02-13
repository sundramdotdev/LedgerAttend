import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  String _searchKeyword = '';

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? eventId = args?['eventId'];
    final String? eventName = args?['eventName'];

    if (eventId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member List')),
        body: const Center(child: Text('Error: No Event Selected')),
      );
    }

    debugPrint('Fetching members for event: $eventId');

    return Scaffold(
      appBar: AppBar(title: Text('Members: ${eventName ?? "Unknown"}')),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Search by Name or Roll No',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .doc(eventId)
                    .collection('assigned_members')
                    .orderBy('assignedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!.docs;

                  // Filter data based on search keyword
                  final filteredDocs = data.where((doc) {
                    final studentData = doc.data() as Map<String, dynamic>;
                    final name = (studentData['name'] ?? '')
                        .toString()
                        .toLowerCase();
                    final rollNumber = (studentData['rollNo'] ?? '')
                        .toString()
                        .toLowerCase();
                    final keyword = _searchKeyword.toLowerCase();

                    return name.contains(keyword) ||
                        rollNumber.contains(keyword);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No members found',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final studentData = doc.data() as Map<String, dynamic>;
                      final name = studentData['name'] ?? 'Unknown';
                      final rollNo = studentData['rollNo'] ?? 'N/A';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text('Roll No: $rollNo'),
                        ),
                      );
                    },
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
