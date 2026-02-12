import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  final MapController _mapController = MapController();

  // Default location (fallback)
  LatLng _initialCenter = const LatLng(28.6139, 77.2090); 
  LatLng? _selectedLocation;
  double _radius = 100.0; // Default radius in meters
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Using default location.'),
        ));
      }
      setState(() => _isLoadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Location permissions are denied. Using default location.'),
            ));
         }
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
       if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are permanently denied. Using default location.'),
          ));
       }
      setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _initialCenter = LatLng(position.latitude, position.longitude);
          _selectedLocation = _initialCenter; // Auto-select current location
          _isLoadingLocation = false;
        });
        // Move map after frame build
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(_initialCenter, 16.0);
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  Future<void> _submitEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location on the map')),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('events').add({
          'eventName': _eventNameController.text.trim(),
          'eventDescription': _eventDescriptionController.text.trim(),
          'location': GeoPoint(
              _selectedLocation!.latitude, _selectedLocation!.longitude),
          'radius': _radius,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true, // Mark event as active
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event Created Successfully!')),
          );
          Navigator.pop(context); // Return to dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating event: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: _isLoadingLocation 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _eventNameController,
                      decoration: const InputDecoration(
                        labelText: 'Event Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter event name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _eventDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Event Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: 16.0,
                  onTap: _onTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ledger_attend',
                  ),
                  if (_selectedLocation != null) ...[
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _selectedLocation!,
                          color: Colors.blue.withValues(alpha: 0.3),
                          borderStrokeWidth: 2,
                          borderColor: Colors.blue,
                          useRadiusInMeter: true,
                          radius: _radius,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_selectedLocation != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                child: Text(
                  'Selected Location: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Event Radius: ${_radius.round()} meters'),
                    Slider(
                      value: _radius,
                      min: 10,
                      max: 500,
                      divisions: 49, // (500-10)/10 = 49 steps roughly
                      label: '${_radius.round()}m',
                      onChanged: (value) {
                        setState(() {
                          _radius = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitEvent,
                  child: const Text('Create Event', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
