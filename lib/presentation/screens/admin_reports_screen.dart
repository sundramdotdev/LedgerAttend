import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  void _showExportDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _ExportDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Report',
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No attendance records found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String name = data['studentName'] ?? 'Unknown Student';
              final Timestamp? timestamp = data['timestamp'];
              final String? selfieUrl = data['selfieUrl'];
              final String formattedTime = timestamp != null
                  ? DateFormat('MMM d, y - h:mm a').format(timestamp.toDate())
                  : 'No time';
              // Added eventName if available in data, or just show basic info
              final String eventName = data['eventName'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: GestureDetector(
                    onTap: () {
                      if (selfieUrl != null && selfieUrl.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              Dialog(child: Image.network(selfieUrl)),
                        );
                      }
                    },
                    child: CircleAvatar(
                      backgroundImage: selfieUrl != null && selfieUrl.isNotEmpty
                          ? NetworkImage(selfieUrl)
                          : null,
                      radius: 25,
                      child: selfieUrl == null || selfieUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$eventName\n$formattedTime'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExportDialog extends StatefulWidget {
  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  String? _selectedEventId;
  bool _isExporting = false;

  Future<void> _exportAttendanceToCSV(String eventId) async {
    setState(() => _isExporting = true);

    try {
      // Fetch Data
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('eventId', isEqualTo: eventId)
          .orderBy('timestamp')
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No records found for this event')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Convert to List
      List<List<dynamic>> rows = [
        ['Student Name', 'Roll No', 'Time', 'Date', 'Photo URL'],
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String name = data['studentName'] ?? 'Unknown';
        final String rollNo = data['rollNo'] ?? 'N/A';
        final Timestamp? ts = data['timestamp'];
        final String photoUrl = data['selfieUrl'] ?? '';

        String timeStr = '';
        String dateStr = '';
        if (ts != null) {
          final dt = ts.toDate();
          timeStr = DateFormat('h:mm a').format(dt);
          dateStr = DateFormat('yyyy-MM-dd').format(dt);
        }

        rows.add([name, rollNo, timeStr, dateStr, photoUrl]);
      }

      // CSV String
      String csvContent = const ListToCsvConverter().convert(rows);

      // Save and Share
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/attendance_export_$eventId.csv';
      final file = File(path);
      await file.writeAsString(csvContent);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        await Share.shareXFiles([XFile(path)], text: 'Attendance Report');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export Failed: $e')));
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Attendance'),
      content: _isExporting
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Generating Report..."),
              ],
            )
          : SizedBox(
              width: double.maxFinite,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) return const LinearProgressIndicator();

                  List<DropdownMenuItem<String>> items = [];
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    items.add(
                      DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['eventName'] ?? 'Unnamed'),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _selectedEventId,
                    hint: const Text('Select Event to Export'),
                    items: items,
                    onChanged: (val) => setState(() => _selectedEventId = val),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
            ),
      actions: _isExporting
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _selectedEventId == null
                    ? null
                    : () => _exportAttendanceToCSV(_selectedEventId!),
                child: const Text('Download CSV'),
              ),
            ],
    );
  }
}
