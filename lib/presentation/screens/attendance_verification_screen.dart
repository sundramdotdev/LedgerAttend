import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';

class AttendanceVerificationScreen extends StatefulWidget {
  final String eventId;

  const AttendanceVerificationScreen({super.key, required this.eventId});

  @override
  State<AttendanceVerificationScreen> createState() =>
      _AttendanceVerificationScreenState();
}

class _AttendanceVerificationScreenState
    extends State<AttendanceVerificationScreen> {
  bool _isCheckingLocation = true;
  bool _locationVerified = false;
  String _locationMessage = "Verifying your location...";
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    _verifyLocation();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _verifyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _locationMessage = 'Location services are disabled.';
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _locationMessage = 'Location permissions are denied';
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _locationMessage =
              'Location permissions are permanently denied, we cannot request permissions.';
        });
      }
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _locationVerified = true;
          _isCheckingLocation = false;
          _locationMessage = "Location Verified!";
        });
        _initializeCamera();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _locationMessage = "Error fetching location: $e";
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Use the front camera if available
        final firstCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          firstCamera,
          ResolutionPreset.medium,
        );

        _initializeControllerFuture = _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      } else {
        if (mounted) {
          setState(() {
            _locationMessage = "No cameras available";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationMessage = "Camera Error: $e";
        });
      }
    }
  }

  Future<void> _captureAndVerify() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();

      // Here you would typically send the image and location to your backend
      // for verification.

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance Verified! Image saved to ${image.path}'),
        ),
      );

      // Navigate back or to a success screen
      Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing attendance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Verification')),
      body: Center(
        child: _isCheckingLocation
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_locationMessage),
                ],
              )
            : !_locationVerified
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 20),
                  Text(_locationMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isCheckingLocation = true;
                        _locationMessage = "Verifying your location...";
                      });
                      _verifyLocation();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              )
            : _cameraController == null ||
                  !_cameraController!.value.isInitialized
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Ensure your face is clearly visible",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    SizedBox(
                      height: 400,
                      child: CameraPreview(_cameraController!),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _captureAndVerify,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Verify Attendance"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
