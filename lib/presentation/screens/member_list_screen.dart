import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/student_model.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  String _searchKeyword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member List'),
      ),
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
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!.docs;
                  
                  // Filter data based on search keyword
                  final filteredDocs = data.where((doc) {
                    final studentData = doc.data() as Map<String, dynamic>;
                    final name = studentData['name'].toString().toLowerCase();
                    final rollNumber = studentData['rollNumber'].toString().toLowerCase();
                    final keyword = _searchKeyword.toLowerCase();
                    
                    return name.contains(keyword) || rollNumber.contains(keyword);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      // Use try-catch or safe parsing if model expects specific fields
                      final student = Student.fromMap(
                          doc.data() as Map<String, dynamic>, doc.id);

                      return Card(
                        key: ValueKey(student.id),
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              student.name.isNotEmpty
                                  ? student.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(student.name),
                          subtitle: Text('Roll No: ${student.rollNumber}'),
                          trailing: IconButton(
                              icon: const Icon(Icons.arrow_forward_ios,
                                  size: 16),
                              onPressed: () {
                                // Navigate to details or edit
                              }),
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
