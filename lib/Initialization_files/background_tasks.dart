// File: lib/Initialization_files/background_tasks.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Main background task name
const String LOCATION_BACKGROUND_TASK = 'com.medcave.updateDriverLocation';
const String DRIVER_STATUS_CHECK_TASK = 'com.medcave.checkDriverStatus';
const String KEY_DRIVER_ID = 'driver_id';
const String KEY_IS_DRIVER_ACTIVE = 'is_driver_active';

// Initialize Workmanager in your main.dart file
void initializeBackgroundTasks() {
  try {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    if (kDebugMode) {
      print("Workmanager initialized successfully");
    }
  } catch (e) {
    if (kDebugMode) {
      print("Error initializing Workmanager: $e");
    }
  }
}

// The callback dispatcher that will be called by Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case LOCATION_BACKGROUND_TASK:
          return await _handleLocationUpdateTask();
        case DRIVER_STATUS_CHECK_TASK:
          return await _handleDriverStatusCheckTask();
        default:
          return Future.value(true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Background task error: $e');
      }
      return Future.value(false);
    }
  });
}

// Handle location update background task
Future<bool> _handleLocationUpdateTask() async {
  try {
    // Get stored driver ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? driverId = prefs.getString(KEY_DRIVER_ID);

    // Important: Use .getBool and check for null, defaulting to false
    final bool isActive = prefs.getBool(KEY_IS_DRIVER_ACTIVE) ?? false;

    if (kDebugMode) {
      print(
          'Background location task - Driver ID: $driverId, Active: $isActive');
    }

    if (driverId != null && isActive) {
      // Check Firestore for the latest status as well (double verification)
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();

      // Only continue if driver exists and is active in Firestore
      if (driverDoc.exists) {
        final firestoreActive = driverDoc.data()?['isDriverActive'] ?? false;

        if (!firestoreActive) {
          // Update SharedPreferences to match Firestore
          await prefs.setBool(KEY_IS_DRIVER_ACTIVE, false);

          if (kDebugMode) {
            print(
                'Driver is not active in Firestore, skipping location update');
          }
          return true;
        }
      }

      // Get current location
      final position = await _determinePosition();

      // Update location in Firestore
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

      // Also store in location history collection
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .collection('locationHistory')
          .add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': position.heading,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print(
            'Background location updated: ${position.latitude}, ${position.longitude}');
      }
    } else {
      if (kDebugMode) {
        print(
            'Background location update skipped - Driver not active or not found');
      }
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('Location update task error: $e');
    }
    return false;
  }
}

// Handle driver status check background task
Future<bool> _handleDriverStatusCheckTask() async {
  try {
    // Get stored driver ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? driverId = prefs.getString(KEY_DRIVER_ID);

    if (driverId != null) {
      // Check driver status from Firestore
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();

      if (driverDoc.exists) {
        final data = driverDoc.data();
        if (data != null) {
          final bool isActive = data['isDriverActive'] ?? false;

          // Update shared preferences with new status
          await prefs.setBool(KEY_IS_DRIVER_ACTIVE, isActive);

          if (kDebugMode) {
            print('Background driver status check - Active: $isActive');
          }

          // If active, make sure our background task is running
          if (isActive) {
            // Ensure the location update task is running
            Workmanager().registerPeriodicTask(
              'driverLocationUpdate',
              LOCATION_BACKGROUND_TASK,
              frequency: const Duration(minutes: 15),
              constraints: Constraints(
                networkType: NetworkType.connected,
              ),
              existingWorkPolicy: ExistingWorkPolicy.keep,
            );
          }
        }
      }
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('Driver status check task error: $e');
    }
    return false;
  }
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

class BackgroundTasks {
  /// Initialize all background tasks
  static void initialize() {
    try {
      if (kDebugMode) {
        print("Initializing background tasks...");
      }

      // Initialize location updates service if available
      try {
        LocationUpdateService.initialize();
        if (kDebugMode) {
          print("Location update service initialized successfully");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Warning: Failed to initialize location update service: $e");
        }
      }

      // Add other background services here as needed

      if (kDebugMode) {
        print("All background tasks initialized successfully");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing background tasks: $e");
      }
      // Rethrow to be handled by caller
      rethrow;
    }
  }
}

/// Stub implementation of LocationUpdateService
/// Replace with actual implementation if available
class LocationUpdateService {
  static void initialize() {
    // Implementation should be in the imported file
    if (kDebugMode) {
      print("LocationUpdateService initialize method called");
    }
  }
}
