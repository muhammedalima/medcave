import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Main background task name
const String LOCATION_BACKGROUND_TASK = 'com.medcave.updateDriverLocation';

// Initialize Workmanager in your main.dart file
void initializeBackgroundTasks() {
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );
}

// The callback dispatcher that will be called by Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == LOCATION_BACKGROUND_TASK) {
        // Get stored driver ID from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final String? driverId = prefs.getString('driver_id');
        final bool? isActive = prefs.getBool('is_driver_active');
        
        if (driverId != null && isActive == true) {
          // Get current location
          final position = await _determinePosition();
          
          // Update location using the database function
          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(driverId)
              .update({
                'location': {
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                  'heading': position.heading,
                  'speed': position.speed,
                  'timestamp': FieldValue.serverTimestamp(),
                  'accuracy': position.accuracy,
                },
                'lastLocationUpdate': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          debugPrint('Background location updated: ${position.latitude}, ${position.longitude}');
        }
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}

// Helper function to determine position with proper error handling
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.');
  } 

  // Get the current position with high accuracy
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

class DriverLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Timer for foreground location updates
  static Timer? _locationTimer;
  
  // Initialize location service and request permissions
  static Future<void> initialize() async {
    try {
      // Request location permissions
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied');
        return;
      }
      
      // Store driver ID in SharedPreferences for background tasks
      final user = _auth.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('driver_id', user.uid);
      }
      
      debugPrint('Driver location service initialized');
    } catch (e) {
      debugPrint('Error initializing location service: $e');
    }
  }

  // Start location updates when driver becomes active
  static Future<void> startLocationUpdates() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Store active status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_driver_active', true);
      
      // Start foreground updates
      _startForegroundUpdates();
      
      // Register background task
      // Note: 15 minutes is the minimum allowed by Workmanager
      Workmanager().registerPeriodicTask(
        'driverLocationUpdate',
        LOCATION_BACKGROUND_TASK,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      
      debugPrint('Location updates started for driver: ${user.uid}');
    } catch (e) {
      debugPrint('Error starting location updates: $e');
    }
  }
  
  // Start foreground location updates (when app is open)
  static void _startForegroundUpdates() {
    // Cancel any existing timer
    _locationTimer?.cancel();
    
    // Create new timer that fires every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _updateCurrentLocation();
    });
    
    // Also update location immediately
    _updateCurrentLocation();
  }
  
  // Update current location in Firestore
  static Future<void> _updateCurrentLocation() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Get current position
      final position = await _determinePosition();
      
      // Update in Firestore
      await _firestore.collection('drivers').doc(user.uid).update({
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'heading': position.heading,
          'speed': position.speed,
          'timestamp': FieldValue.serverTimestamp(),
          'accuracy': position.accuracy,
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }
  
  // Stop location updates when driver becomes inactive
  static Future<void> stopLocationUpdates() async {
    try {
      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_driver_active', false);
      
      // Cancel foreground timer
      _locationTimer?.cancel();
      _locationTimer = null;
      
      // Cancel background tasks
      Workmanager().cancelByTag('driverLocationUpdate');
      
      debugPrint('Location updates stopped');
    } catch (e) {
      debugPrint('Error stopping location updates: $e');
    }
  }
}