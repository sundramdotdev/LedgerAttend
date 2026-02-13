import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  String? _selectedEventId;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Function to process CSV Import
  Future<void> _importCSV() async {
    if (_selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event first')),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        // Show Progress Dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        }

        final file = File(result.files.single.path!);
        final input = file.openRead();
        final fields = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter())
            .toList();

        int successCount = 0;

        // Batch writes
        WriteBatch batch = FirebaseFirestore.instance.batch();
        int batchCount = 0;

        // Skip header row (index 0)
        for (int i = 1; i < fields.length; i++) {
          var row = fields[i];
          // Check if row has enough columns (name, rollNo, section, email, mobile)
          if (row.length < 5) continue;

          String name = row[0].toString().trim();
          String rollNo = row[1].toString().trim();
          String section = row[2].toString().trim();
          String email = row[3].toString().trim().toLowerCase();
          String mobile = row[4].toString().trim();

          if (email.isEmpty) continue;

          DocumentReference docRef = FirebaseFirestore.instance
              .collection('events')
              .doc(_selectedEventId)
              .collection('assigned_members')
              .doc(email);

          batch.set(docRef, {
            'name': name,
            'rollNo': rollNo,
            'course': section,
            'mobile': mobile,
            'email': email,
            'eventId': _selectedEventId,
          });

          debugPrint(
            'Member saved to: events/$_selectedEventId/assigned_members/$email',
          );

          successCount++;
          batchCount++;

          // Commit batch every 400 records
          if (batchCount >= 400) {
            await batch.commit();
            batch = FirebaseFirestore.instance.batch();
            batchCount = 0;
          }
        }

        // Commit remaining
        if (batchCount > 0) {
          await batch.commit();
        }

        if (mounted) {
          Navigator.pop(context); // Close Progress Dialog

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Import Complete"),
              content: Text("Successfully imported $successCount items."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Close dialog if likely open, but safer to just show snackbar
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing CSV: $e')));
      }
    }
  }

  // Function to download CSV Template
  Future<void> _downloadTemplate() async {
    try {
      final String csvContent = const ListToCsvConverter().convert([
        ['name', 'rollNo', 'section', 'email', 'mobile'],
        ['John Doe', '123', 'CS-A', 'student@example.com', '9876543210'],
      ]);

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/student_upload_template.csv';
      final file = File(path);
      await file.writeAsString(csvContent);

      // Share the file
      await Share.shareXFiles([XFile(path)], text: 'Student Upload Template');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing template: $e')));
      }
    }
  }

  Future<void> _submitMember() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedEventId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Select an event')));
        return;
      }

      try {
        String email = _emailController.text.trim().toLowerCase();
        await FirebaseFirestore.instance
            .collection('events')
            .doc(_selectedEventId)
            .collection('assigned_members')
            .doc(email)
            .set({
              'name': _nameController.text.trim(),
              'rollNo': _rollNoController.text.trim(),
              'course': _courseController.text.trim(),
              'mobile': _mobileController.text.trim(),
              'email': email,
              'assignedAt': FieldValue.serverTimestamp(),
              'eventId': _selectedEventId,
            });

        debugPrint(
          'Member saved to: events/$_selectedEventId/assigned_members/$email',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member Added Successfully')),
          );
          _nameController.clear();
          _rollNoController.clear();
          _courseController.clear();
          _mobileController.clear();
          _emailController.clear();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member to Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Event Dropdown
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .where('isActive', isEqualTo: true)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error loading events: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    List<DropdownMenuItem<String>> eventItems = [];
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      eventItems.add(
                        DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['eventName'] ?? 'Unnamed Event'),
                        ),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _selectedEventId,
                      hint: const Text('Select Event'),
                      items: eventItems,
                      onChanged: (value) {
                        setState(() {
                          _selectedEventId = value;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      validator: (value) =>
                          value == null ? 'Please select an event' : null,
                    );
                  },
                ),

                const SizedBox(height: 16),

                // BULK IMPORT SECTION
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Bulk Import",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // ...
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _importCSV,
                            icon: const Icon(Icons.upload_file),
                            label: const Text("Upload CSV"),
                          ),
                          TextButton.icon(
                            onPressed: _downloadTemplate,
                            icon: const Icon(Icons.download),
                            label: const Text("Template"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("OR Manually Add"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Student Details Form
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rollNoController,
                  decoration: const InputDecoration(
                    labelText: 'Roll No',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(
                    labelText: 'Course / Section',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile No',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    hintText: 'This will be their login ID',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid Email';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitMember,
                    child: const Text(
                      'Add Member',
                      style: TextStyle(fontSize: 18),
                    ),
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
