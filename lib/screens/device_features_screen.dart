/// device_features_screen.dart
/// Week 9 — Device Features Integration
/// Demonstrates camera capture and GPS location retrieval
/// with reverse geocoding integrated into the Retail Analytics Engine.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class DeviceFeaturesScreen extends StatefulWidget {
  const DeviceFeaturesScreen({super.key});

  @override
  State<DeviceFeaturesScreen> createState() => _DeviceFeaturesScreenState();
}

class _DeviceFeaturesScreenState extends State<DeviceFeaturesScreen> {
  // Camera state
  File? _capturedImage;
  String _imageStatus = 'No photo captured yet';
  DateTime? _photoTimestamp;

  // GPS state
  double? _latitude;
  double? _longitude;
  double? _altitude;
  String _locationName = '';
  String _locationStatus = 'Location not retrieved yet';
  bool _isLoadingLocation = false;

  final ImagePicker _picker = ImagePicker();

  // ─── CAMERA ────────────────────────────────────────────────────────────────

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (photo == null) {
        setState(() => _imageStatus = 'Photo capture cancelled');
        return;
      }

      setState(() {
        _capturedImage = File(photo.path);
        _photoTimestamp = DateTime.now();
        _imageStatus =
            'Photo captured at ${DateFormat('dd MMM yyyy, HH:mm:ss').format(_photoTimestamp!)}';
      });
    } catch (e) {
      setState(() => _imageStatus = 'Camera error: $e');
      _showErrorSnackBar('Could not access camera. Check permissions.');
    }
  }

  // ─── GPS ───────────────────────────────────────────────────────────────────

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Requesting location...';
    });

    // Step 1: Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoadingLocation = false;
        _locationStatus = 'GPS is disabled on this device';
      });
      _showErrorSnackBar('Please enable GPS in your device settings.');
      return;
    }

    // Step 2: Check/request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatus = 'Location permission denied';
        });
        _showErrorSnackBar('Location permission is required for GPS.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoadingLocation = false;
        _locationStatus = 'Location permission permanently denied';
      });
      _showErrorSnackBar(
        'Permission permanently denied. Enable it in App Settings.',
      );
      return;
    }

    // Step 3: Get the actual position
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _altitude = position.altitude;
        _isLoadingLocation = false;
        _locationStatus =
            'Location retrieved at ${DateFormat('HH:mm:ss').format(DateTime.now())}';
      });

      // Step 4: Reverse geocode to get human-readable location name
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [
            if (place.street != null && place.street!.isNotEmpty) place.street!,
            if (place.subLocality != null && place.subLocality!.isNotEmpty)
              place.subLocality!,
            if (place.locality != null && place.locality!.isNotEmpty)
              place.locality!,
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty)
              place.administrativeArea!,
            if (place.country != null && place.country!.isNotEmpty)
              place.country!,
          ];
          setState(() {
            _locationName = parts.join(', ');
          });
        }
      } catch (_) {
        // Geocoding failed silently — coordinates still show correctly
        setState(() => _locationName = '');
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationStatus = 'Could not retrieve location: $e';
      });
      _showErrorSnackBar(
        'GPS error. Make sure you are outdoors or near a window.',
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Device Features',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF22C55E).withAlpha(60),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.phone_android, color: Color(0xFF22C55E), size: 36),
                  SizedBox(height: 6),
                  Text(
                    'Retail Analytics Engine',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Camera & GPS Integration — Week 9',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── CAMERA SECTION ──
            _sectionTitle('Camera Integration', Icons.camera_alt_outlined),
            const SizedBox(height: 10),

            // ImageView
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF22C55E).withAlpha(40),
                ),
              ),
              child: _capturedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_capturedImage!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Captured image will appear here',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 10),

            // Image status
            _statusCard(
              icon: Icons.info_outline,
              text: _imageStatus,
              color: _capturedImage != null
                  ? const Color(0xFF22C55E)
                  : Colors.grey,
            ),

            const SizedBox(height: 12),

            // Capture Photo button
            ElevatedButton.icon(
              onPressed: _capturePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'CAPTURE PHOTO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 24),

            // ── GPS SECTION ──
            _sectionTitle('GPS Location', Icons.location_on_outlined),
            const SizedBox(height: 10),

            // Latitude
            _coordCard(
              label: 'Latitude',
              value: _latitude != null ? _latitude!.toStringAsFixed(6) : '—',
              icon: Icons.south_outlined,
            ),

            const SizedBox(height: 8),

            // Longitude
            _coordCard(
              label: 'Longitude',
              value: _longitude != null ? _longitude!.toStringAsFixed(6) : '—',
              icon: Icons.east_outlined,
            ),

            const SizedBox(height: 8),

            // Altitude
            _coordCard(
              label: 'Altitude',
              value: _altitude != null
                  ? '${_altitude!.toStringAsFixed(1)} m'
                  : '—',
              icon: Icons.height_outlined,
            ),

            // Location name (reverse geocoded)
            if (_locationName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withAlpha(30),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Location',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Location status
            _statusCard(
              icon: _isLoadingLocation
                  ? Icons.hourglass_empty
                  : Icons.gps_fixed,
              text: _locationStatus,
              color: _latitude != null
                  ? const Color(0xFF22C55E)
                  : _isLoadingLocation
                  ? Colors.orange
                  : Colors.grey,
            ),

            const SizedBox(height: 12),

            // Get Location button
            ElevatedButton.icon(
              onPressed: _isLoadingLocation ? null : _getLocation,
              icon: _isLoadingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _isLoadingLocation ? 'RETRIEVING LOCATION...' : 'GET LOCATION',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // ── COMBINED SUMMARY ──
            if (_capturedImage != null && _latitude != null) ...[
              const SizedBox(height: 24),
              _sectionTitle('Product Field Record', Icons.inventory_2_outlined),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withAlpha(60),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Combined Capture Summary',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _capturedImage!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _summaryRow('Latitude', _latitude!.toStringAsFixed(6)),
                    _summaryRow('Longitude', _longitude!.toStringAsFixed(6)),
                    _summaryRow(
                      'Altitude',
                      '${_altitude!.toStringAsFixed(1)} m',
                    ),
                    if (_locationName.isNotEmpty)
                      _summaryRow('Location', _locationName),
                    _summaryRow(
                      'Captured',
                      DateFormat(
                        'dd MMM yyyy, HH:mm:ss',
                      ).format(_photoTimestamp!),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF22C55E), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _coordCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF22C55E).withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF22C55E)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF22C55E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
