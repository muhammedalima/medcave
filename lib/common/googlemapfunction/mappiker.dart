import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<LocationPermission> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  static Future<Map<String, dynamic>> getCurrentLocation() async {
    final permission = await checkAndRequestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    final position = await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return {
      'location': LatLng(position.latitude, position.longitude),
      'address': placemarks.first.street ?? '',
    };
  }

  static Future<String> getAddressFromLatLng(LatLng location) async {
    final placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );
    return placemarks.first.street ?? '';
  }
}

class MapPicker extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPicker({super.key, this.initialLocation});

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  // ignore: unused_field
  late GoogleMapController _controller;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (_selectedLocation == null) {
      try {
        final currentLocation = await LocationService.getCurrentLocation();
        setState(() {
          _selectedLocation = currentLocation['location'] as LatLng;
        });
      } catch (e) {
        // Use default location if unable to get current location
        _selectedLocation = const LatLng(0, 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose Location',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedLocation),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _selectedLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation!,
                zoom: 15,
              ),
              onMapCreated: (controller) => _controller = controller,
              onTap: (location) {
                setState(() => _selectedLocation = location);
              },
              markers: _selectedLocation == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedLocation!,
                      ),
                    },
            ),
    );
  }
}