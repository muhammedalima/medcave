import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A standalone service to handle driver location updates in the background
class DriverLocationService {
  static const String _locationTaskName = 'driverLocationUpdate';
  static const Duration _foregroundUpdateInterval = Duration(seconds: 15);
  static Timer? _foregroundTimer;
  static StreamSubscription<Position>? _positionStream;
  
  // Initialize location permissions and workmanager
  static Future<void> initialize() async {
    // Initialize workmanager for background tasks
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    // Request location permissions
    await _checkLocationPermission();
    
    // Check if driver is already active (from shared prefs)
    final prefs = await SharedPreferences.getInstance();
    final isDriverActive = prefs.getBool('isDriverActive') ?? false;
    
    if (isDriverActive) {
      // If driver was active, restart location updates
      await startLocationUpdates();
    }
  }
  
  /// Check and request location permissions
  static Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return false;
    }
    
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return false;
    }
    
    // Permissions are granted
    return true;
  }
  
  /// Start location updates both in foreground and background
  static Future<void> startLocationUpdates() async {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null) {
      debugPrint('Cannot start location updates: No driver ID');
      return;
    }
    
    // Store driver active status in shared prefs for persistence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDriverActive', true);
    await prefs.setString('driverId', driverId);
    
    // Start foreground updates
    _startForegroundUpdates();
    
    // Register background task
    await _registerBackgroundTask();
    
    debugPrint('Location updates started for driver: $driverId');
  }
  
  /// Stop all location updates
  static Future<void> stopLocationUpdates() async {
    // Cancel foreground timer and position stream
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    
    // Cancel position stream if active
    await _positionStream?.cancel();
    _positionStream = null;
    
    // Cancel background task
    await Workmanager().cancelByTag(_locationTaskName);
    
    // Update shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDriverActive', false);
    
    debugPrint('Location updates stopped');
  }
  
  /// Start foreground location updates using timer
  static void _startForegroundUpdates() {
    // Cancel existing timer if any
    _foregroundTimer?.cancel();
    
    // Setup periodic location updates while app is in foreground
    _foregroundTimer = Timer.periodic(_foregroundUpdateInterval, (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        await _updateLocationInFirestore(position);
      } catch (e) {
        debugPrint('Error updating location in foreground: $e');
      }
    });
    
    // Also start a continuous position stream for more responsive updates
    _startPositionStream();
  }
  
  /// Start a continuous position stream for more responsive location updates
  static void _startPositionStream() {
    // Cancel existing stream if any
    _positionStream?.cancel();
    
    // Start new position stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 10 meters
      ),
    ).listen((Position position) async {
      try {
        await _updateLocationInFirestore(position);
      } catch (e) {
        debugPrint('Error in position stream: $e');
      }
    });
  }
  
  /// Register background location update task
  static Future<void> _registerBackgroundTask() async {
    await Workmanager().registerPeriodicTask(
      'locationUpdate',
      _locationTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 1),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      tag: _locationTaskName,
    );
    
    debugPrint('Background location task registered');
  }
  
  /// Update driver's location in Firestore
  static Future<void> _updateLocationInFirestore(Position position) async {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    final prefs = await SharedPreferences.getInstance();
    final storedDriverId = prefs.getString('driverId');
    final isDriverActive = prefs.getBool('isDriverActive') ?? false;
    
    // Use stored driver ID if current user is null (background task)
    final effectiveDriverId = driverId ?? storedDriverId;
    
    // Only update if driver is active and we have a driver ID
    if (effectiveDriverId != null && isDriverActive) {
      try {
        final firestore = FirebaseFirestore.instance;
        
        // Update location in drivers collection
        await firestore.collection('drivers').doc(effectiveDriverId).update({
          'location': GeoPoint(position.latitude, position.longitude),
          'heading': position.heading,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        // Also update location in a separate collection for historical tracking
        await firestore.collection('driver_locations').add({
          'driverId': effectiveDriverId,
          'location': GeoPoint(position.latitude, position.longitude),
          'heading': position.heading,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        debugPrint('Error updating location in Firestore: $e');
      }
    }
  }
}

/// The background task callback that will be called by workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == DriverLocationService._locationTaskName) {
        // Get the current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        // Update location in Firestore
        await DriverLocationService._updateLocationInFirestore(position);
        
        return true;
      }
    } catch (e) {
      debugPrint('Error in background task: $e');
      return false;
    }
    return true;
  });
}