import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentMapScreen extends StatefulWidget {
  // Removed single event constructor to support all active events
  const StudentMapScreen({super.key});

  @override
  State<StudentMapScreen> createState() => _StudentMapScreenState();
}

class _StudentMapScreenState extends State<StudentMapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isMocked = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndListen();
  }

  Future<void> _checkPermissionsAndListen() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy:
          LocationAccuracy.bestForNavigation, // High accuracy for geofencing
      distanceFilter: 2, // Update every 2 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
                _isMocked = position.isMocked;
                _isLoading = false;
              });
            }
          },
          onError: (e) {
            debugPrint("Location Stream Error: $e");
          },
        );
    // Get initial position for immediate display
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((
      Position position,
    ) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isMocked = position.isMocked;
          _isLoading = false;
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            16,
          );
        });
      }
    });
  }

  // Helper to calculate distance
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(lat1, lon1),
      LatLng(lat2, lon2),
    );
  }

  Future<void> _submitAttendance(String eventId, String eventName) async {
    if (_isMocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot mark attendance with mock location!'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Fetch user details
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      String studentName = userData?['name'] ?? user.displayName ?? 'Unknown';
      String rollNo =
          userData?['rollNo'] ??
          'N/A'; // Assuming rollNo is in users collection, otherwise modify
      String course = userData?['course'] ?? 'N/A';

      // Keep it robust: if not in users, try looking up in assigned_members (optional, based on requirement)
      // For now, proceeding with what we have.

      // Record in Firestore
      // Record in Firestore
      // Use 'attendance' collection to match History Screen query
      // Ensure email is saved and normalized

      final String userEmail = user.email?.trim().toLowerCase() ?? '';

      // Step A: Assignment Check (Anti-Proxy Protection)
      // Verify student is assigned to this specific event BEFORE marking attendance
      DocumentSnapshot assignmentDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .collection('assigned_members')
          .doc(userEmail)
          .get();

      if (!assignmentDoc.exists) {
        throw Exception("You are not assigned to this Class/Event.");
      }

      // Step B: Location check already validated by UI (button only enabled when inside geofence)
      // Step C: Mark attendance
      await FirebaseFirestore.instance.collection('attendance').add({
        'studentName': studentName,
        'rollNo': rollNo,
        'course': course,
        'email': userEmail, // Critical for history query
        'timestamp': FieldValue.serverTimestamp(),
        'eventId': eventId,
        'eventName': eventName,
        'uid': user.uid,
        'status': 'Present',
        'selfieUrl': '', // Placeholder if needed by history UI
      });

      if (!mounted) return;

      // Show Success Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 16),
              const Text(
                "Check-in Successful!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Attendance marked for $eventName"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to Home
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error marking attendance: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error marking attendance: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Attendance Map')),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch ALL events (removed isActive filter for broader visibility)
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading events: ${snapshot.error}"),
            );
          }

          // List of valid events
          final events = snapshot.data?.docs ?? [];

          // Check Geofence Logic here
          String? matchedEventId;
          String? matchedEventName;
          bool isInside = false;

          if (_currentPosition != null) {
            for (var doc in events) {
              final data = doc.data() as Map<String, dynamic>;
              // robustly handle location data
              if (!data.containsKey('location')) continue;
              final GeoPoint loc = data['location'];
              final double radius = (data['radius'] ?? 100).toDouble();

              double distance = _calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                loc.latitude,
                loc.longitude,
              );

              if (distance <= radius) {
                isInside = true;
                matchedEventId = doc.id;
                matchedEventName = data['eventName'];
                break;
              }
            }
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(
                    28.6139,
                    77.2090,
                  ), // Default, will update
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ledger_attend',
                  ),

                  // Draw Circles for ALL events (Green)
                  CircleLayer(
                    circles: events.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (!data.containsKey('location')) {
                        return CircleMarker(
                          point: const LatLng(0, 0),
                          radius: 0,
                          useRadiusInMeter: true,
                          color: Colors.transparent,
                          borderColor: Colors.transparent,
                        );
                      }
                      final GeoPoint loc = data['location'];
                      final double radius = (data['radius'] ?? 100).toDouble();

                      return CircleMarker(
                        point: LatLng(loc.latitude, loc.longitude),
                        color: Colors.green.withValues(
                          alpha: 0.3,
                        ), // Always Green
                        borderStrokeWidth: 2,
                        borderColor: Colors.green, // Always Green border
                        useRadiusInMeter: true,
                        radius: radius,
                      );
                    }).toList(),
                  ),

                  // User Marker (Blue)
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue, // Changed from Red to Blue
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Loading Indicator
              if (_isLoading || _isSubmitting)
                Container(
                  color: Colors.black45,
                  child: const Center(child: CircularProgressIndicator()),
                ),

              // Mock Warning
              if (_isMocked)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black54,
                    child: AlertDialog(
                      title: const Text("Fake GPS Detected"),
                      content: const Text(
                        "You are using a mock location. Security check failed.",
                      ),
                      backgroundColor: Colors.red.shade100,
                    ),
                  ),
                ),

              // Bottom Info Panel
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isMocked)
                          const Text(
                            "⚠️ Security Alert: Mock Location Detected",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (isInside)
                          Column(
                            children: [
                              Text(
                                "You are at: $matchedEventName",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: (_isSubmitting)
                                      ? null
                                      : () => _submitAttendance(
                                          matchedEventId!,
                                          matchedEventName!,
                                        ),
                                  child: Text(
                                    _isSubmitting
                                        ? "Marking..."
                                        : "Mark Attendance",
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              const Text(
                                "You are outside any event venue.",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Move inside a blue circle to mark attendance.",
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: null, // Disabled
                                  style: ElevatedButton.styleFrom(
                                    disabledBackgroundColor:
                                        Colors.grey.shade300,
                                  ),
                                  child: const Text(
                                    "Mark Attendance (Outside)",
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
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              16,
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
