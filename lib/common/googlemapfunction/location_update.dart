// File: lib/common/googlemapfunction/location_update.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constants for SharedPreferences keys
const String KEY_DRIVER_ID = 'driver_id';
const String KEY_IS_DRIVER_ACTIVE = 'is_driver_active';
const String KEY_TIMER_ACTIVE = 'driver_location_timer_active';
const String KEY_TIMER_TICK = 'driver_location_timer_tick';
const String KEY_TIMER_LAST_UPDATE = 'driver_location_timer_last_update';

// Constants for background tasks
const String LOCATION_BACKGROUND_TASK = 'com.medcave.updateDriverLocation';
const String DRIVER_STATUS_CHECK_TASK = 'com.medcave.checkDriverStatus';

class DriverLocationService {
  // Static instance for singleton pattern
  static final DriverLocationService _instance =
      DriverLocationService._internal();
  factory DriverLocationService() => _instance;
  DriverLocationService._internal();

  // Dependencies
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  bool _isInitialized = false;
  bool _isDriverActive = false;
  bool _isServiceRunning = false;

  // Timer for foreground location updates
  Timer? _locationTimer;

  // Timer for self-checks
  Timer? _selfCheckTimer;

  // Timer for checking driver status
  Timer? _statusCheckTimer;

  // Stream subscription for driver status changes
  StreamSubscription<DocumentSnapshot>? _driverStatusSubscription;

  // Check if location permissions are granted and location service is enabled
  Future<bool> checkLocationPermissions() async {
    try {
      if (kDebugMode) {
        print('Checking location permissions...');
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled');
        }
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('Location permissions denied');
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('Location permissions permanently denied');
        }
        return false;
      }

      if (kDebugMode) {
        print('Location permissions granted: $permission');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permissions: $e');
      }
      return false;
    }
  }

  // Initialize location service and request permissions
  Future<bool> initialize() async {
    // Prevent double initialization
    if (_isInitialized) {
      if (kDebugMode) {
        print('DriverLocationService already initialized');
      }
      return true;
    }

    try {
      if (kDebugMode) {
        print('Initializing DriverLocationService...');
      }

      // Request and check location permissions first
      bool permissionsGranted = await checkLocationPermissions();
      if (!permissionsGranted) {
        if (kDebugMode) {
          print(
              'Location permissions not granted, service initialization failed');
        }
        return false;
      }

      // Store driver ID in SharedPreferences for background tasks
      final user = _auth.currentUser;
      if (user != null) {
        if (kDebugMode) {
          print('Current user ID: ${user.uid}');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(KEY_DRIVER_ID, user.uid);

        // Check initial driver status
        await _checkInitialDriverStatus(user.uid);

        // Set up listener for driver status changes
        _setupDriverStatusListener(user.uid);

        // Set up periodic status check as a backup
        _startStatusCheckTimer();

        // Start self-check timer to ensure location updates keep running
        _startSelfCheckTimer();

        // Log current status for debugging
        if (kDebugMode) {
          print('Driver status after initialization: $_isDriverActive');

          // Also log what's in SharedPreferences
          final isActiveInPrefs = prefs.getBool(KEY_IS_DRIVER_ACTIVE) ?? false;
          print('Status in SharedPreferences: $isActiveInPrefs');
        }
      } else {
        if (kDebugMode) {
          print('No user logged in, cannot initialize location service');
        }
        return false;
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('DriverLocationService initialized successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing location service: $e');
      }
      return false;
    }
  }

  // Check initial driver status from Firestore
  Future<void> _checkInitialDriverStatus(String driverId) async {
    try {
      if (kDebugMode) {
        print('Checking initial driver status for ID: $driverId');
      }

      final driverDoc =
          await _firestore.collection('drivers').doc(driverId).get();

      if (driverDoc.exists) {
        final data = driverDoc.data();
        if (data != null) {
          final bool isActive = data['isDriverActive'] ?? false;

          if (kDebugMode) {
            print('Driver document exists, isDriverActive = $isActive');
          }

          // Update state
          _isDriverActive = isActive;

          // Store in SharedPreferences for background tasks
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(KEY_IS_DRIVER_ACTIVE, isActive);

          if (kDebugMode) {
            print('Initial driver status set to: $_isDriverActive');
            print(
                'Updated SharedPreferences with is_driver_active = $isActive');
          }

          // Start location updates if active
          if (_isDriverActive) {
            if (kDebugMode) {
              print('Driver is active, starting location updates');
            }
            await onDriverStatusChanged(true);
          }
        }
      } else {
        // Create a default driver document if it doesn't exist
        if (kDebugMode) {
          print(
              'Driver document does not exist, creating default with isDriverActive = false');
        }

        await _firestore.collection('drivers').doc(driverId).set({
          'isDriverActive': false,
          'driverId': driverId,
          'userId': driverId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _isDriverActive = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(KEY_IS_DRIVER_ACTIVE, false);

        if (kDebugMode) {
          print('Created new driver document and set status to inactive');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking initial driver status: $e');
      }
    }
  }

  // Handle driver status changes
  Future<void> onDriverStatusChanged(bool isActive) async {
    // Log the state change first
    if (kDebugMode) {
      print('Driver status changing from $_isDriverActive to $isActive');
    }

    // Update state variable
    _isDriverActive = isActive;

    if (isActive) {
      // Update Firestore to ensure it matches our state
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('drivers').doc(user.uid).update({
            'isDriverActive': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (kDebugMode) {
            print(
                'Firestore updated with isDriverActive = true from status change handler');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error updating Firestore with driver active status: $e');
          }
        }
      }

      // Ensure our service is marked as running
      _isServiceRunning = true;

      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(KEY_IS_DRIVER_ACTIVE, true);

      // Start the location update timer
      startLocationUpdateTimer();

      // Force an immediate update
      await updateLocationNow();

      // Register background tasks
      _registerBackgroundTasks();

      if (kDebugMode) {
        print(
            'Driver activated, timer active: ${_locationTimer?.isActive}, service running: $_isServiceRunning');
      }
    } else {
      // Cancel the timer explicitly
      if (_locationTimer != null) {
        _locationTimer!.cancel();
        _locationTimer = null;

        if (kDebugMode) {
          print('Location timer cancelled');
        }
      }

      // Update state
      _isServiceRunning = false;

      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(KEY_IS_DRIVER_ACTIVE, false);
      await prefs.setBool(KEY_TIMER_ACTIVE, false);

      // Cancel background tasks
      _cancelBackgroundTasks();

      if (kDebugMode) {
        print('Driver deactivated, service stopped');
      }
    }
  }

  // Register background tasks
  void _registerBackgroundTasks() {
    try {
      if (kDebugMode) {
        print('Registering background tasks...');
      }

      // Register location update task
      Workmanager().registerPeriodicTask(
        'driverLocationUpdate',
        LOCATION_BACKGROUND_TASK,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      // Register status check task
      Workmanager().registerPeriodicTask(
        'driverStatusCheck',
        DRIVER_STATUS_CHECK_TASK,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      if (kDebugMode) {
        print('Background tasks registered successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering background tasks: $e');
      }
    }
  }

  // Cancel background tasks
  void _cancelBackgroundTasks() {
    try {
      if (kDebugMode) {
        print('Cancelling background tasks...');
      }

      Workmanager().cancelByTag('driverLocationUpdate');
      Workmanager().cancelByTag('driverStatusCheck');

      if (kDebugMode) {
        print('Background tasks cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling background tasks: $e');
      }
    }
  }

  // Start a dedicated timer for location updates with improved handling
  void startLocationUpdateTimer() {
    // Cancel any existing timer
    if (_locationTimer != null) {
      _locationTimer!.cancel();
      _locationTimer = null;
      if (kDebugMode) {
        print('Cancelled existing location timer');
      }
    }

    if (kDebugMode) {
      print('Creating new location timer...');
    }

    // Create a new timer that won't be garbage collected
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (kDebugMode && timer.tick % 5 == 0) {
        if (kDebugMode) {
          print(
            'Location timer tick: ${timer.tick} (isActive=${timer.isActive})');
        }
      }

      // Always call updateLocationNow directly
      updateLocationNow();

      // Store a reference in SharedPreferences to prevent it from being garbage collected
      _updateTimerStatus(true, timer.tick);
    });

    // Immediately store the timer status
    _updateTimerStatus(true, 0);

    if (kDebugMode) {
      print(
          'Location timer created and started (isActive=${_locationTimer?.isActive})');
    }
  }

  // Update and store timer status
  Future<void> _updateTimerStatus(bool isActive, int tick) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(KEY_TIMER_ACTIVE, isActive);
      await prefs.setInt(KEY_TIMER_TICK, tick);
      await prefs.setInt(
          KEY_TIMER_LAST_UPDATE, DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode && tick % 10 == 0) {
        if (kDebugMode) {
          print('Timer status updated: active=$isActive, tick=$tick');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating timer status: $e');
      }
    }
  }

  // Start self-check timer to periodically verify timer is running
  void _startSelfCheckTimer() {
    // Cancel any existing timer
    _selfCheckTimer?.cancel();

    // Create a new timer that fires every minute
    _selfCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_isDriverActive && !isTimerActive()) {
        if (kDebugMode) {
          print('SELF-CHECK: Timer should be active but isn\'t! Restarting...');
        }

        // Restart the timer
        startLocationUpdateTimer();

        // Force an update
        await updateLocationNow();
      }
    });

    if (kDebugMode) {
      print('Self-check timer started');
    }
  }

  // Update location now with enhanced error handling
  Future<void> updateLocationNow() async {
    try {
      if (kDebugMode) {
        print('Updating location now (direct call)...');
      }

      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('No user logged in, cannot update location');
        }
        return;
      }

      // Always check Firestore directly
      final driverDoc =
          await _firestore.collection('drivers').doc(user.uid).get();
      final isActive = driverDoc.data()?['isDriverActive'] ?? false;

      if (kDebugMode) {
        print('CHECKED FIRESTORE: Driver active status = $isActive');
      }

      if (!isActive) {
        if (kDebugMode) {
          print('Driver not active in Firestore, skipping location update');
        }

        // If our state is inconsistent, fix it
        if (_isDriverActive) {
          await onDriverStatusChanged(false);
        }
        return;
      } else if (isActive && !_isDriverActive) {
        // If Firestore says active but our state says inactive, fix it
        if (kDebugMode) {
          print(
              'State inconsistency detected: Firestore=active, local=inactive. Fixing...');
        }
        await onDriverStatusChanged(true);
      }

      // Get current position with logging and handle errors
      if (kDebugMode) {
        print('Getting current position...');
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit:
              const Duration(seconds: 5), // Add timeout to prevent hanging
        );

        if (kDebugMode) {
          print(
              'POSITION OBTAINED: ${position.latitude}, ${position.longitude}');
        }
      } catch (posError) {
        if (kDebugMode) {
          print('ERROR getting position: $posError');
          print('Attempting to get last known position...');
        }

        // Try to get last known position as fallback
        try {
          position = await Geolocator.getLastKnownPosition() ??
              await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.low,
                timeLimit: const Duration(seconds: 3),
              );

          if (kDebugMode) {
            print(
                'Using fallback position: ${position.latitude}, ${position.longitude}');
          }
        } catch (fallbackError) {
          if (kDebugMode) {
            print('Failed to get position with fallback: $fallbackError');
          }
          return; // Exit if we can't get any position
        }
      }

      // Update in Firestore with explicit error handling
      try {
        if (kDebugMode) {
          print('Updating Firestore with new location...');
        }

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

        if (kDebugMode) {
          print('FIRESTORE UPDATED with main location!');
        }
      } catch (firestoreError) {
        if (kDebugMode) {
          print('ERROR updating main location in Firestore: $firestoreError');
        }
        // Continue to try updating location history even if main update fails
      }

      // Add to location history with separate try/catch
      try {
        await _firestore
            .collection('drivers')
            .doc(user.uid)
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
          print('LOCATION HISTORY added successfully');
        }
      } catch (historyError) {
        if (kDebugMode) {
          print('ERROR adding to location history: $historyError');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('CRITICAL ERROR in updateLocationNow: $e');
      }
    }
  }

  // Set up listener for driver status changes
  void _setupDriverStatusListener(String driverId) {
    try {
      if (kDebugMode) {
        print('Setting up Firestore driver status listener for ID: $driverId');
      }

      // Cancel existing subscription if any
      _driverStatusSubscription?.cancel();

      // Listen for changes to the driver document
      _driverStatusSubscription = _firestore
          .collection('drivers')
          .doc(driverId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            final bool newIsActive = data['isDriverActive'] ?? false;

            if (kDebugMode) {
              print('Firestore listener received status: $newIsActive');
            }

            // Only take action if status has changed
            if (newIsActive != _isDriverActive) {
              // Call our direct status change handler
              await onDriverStatusChanged(newIsActive);
            }
          }
        }
      }, onError: (error) {
        if (kDebugMode) {
          print('Error in driver status listener: $error');
        }
      });

      if (kDebugMode) {
        print('Firestore driver status listener setup complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up driver status listener: $e');
      }
    }
  }

  // Start timer to periodically check driver status (as backup)
  void _startStatusCheckTimer() {
    // Cancel existing timer if any
    _statusCheckTimer?.cancel();

    if (kDebugMode) {
      print('Starting status check timer (every 15 seconds)');
    }

    // Create new timer that fires every 15 seconds
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 15), (timer) async {
      await _checkDriverStatus();
    });
  }

  // Check driver status periodically as a backup
  Future<void> _checkDriverStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get driver status from Firestore
      final driverDoc =
          await _firestore.collection('drivers').doc(user.uid).get();

      if (driverDoc.exists) {
        final data = driverDoc.data();
        if (data != null) {
          final bool newIsActive = data['isDriverActive'] ?? false;

          // Periodically log the status check (not on every check to avoid log spam)
          if (kDebugMode && DateTime.now().second % 30 == 0) {
            if (kDebugMode) {
              print(
                'Status check: isDriverActive in Firestore: $newIsActive, current state: $_isDriverActive');
            }
          }

          // Only take action if status has changed
          if (newIsActive != _isDriverActive) {
            if (kDebugMode) {
              print('Status inconsistency detected by backup timer!');
              print('Firestore: $newIsActive, Local: $_isDriverActive');
            }

            // Call our direct status change handler
            await onDriverStatusChanged(newIsActive);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking driver status: $e');
      }
    }
  }

  // Set driver active status (can be called from UI)
  Future<bool> setDriverActiveStatus(bool isActive) async {
    try {
      if (kDebugMode) {
        print('Setting driver active status to: $isActive');
      }

      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('No user logged in, cannot set driver status');
        }
        return false;
      }

      // Update in Firestore first
      await _firestore.collection('drivers').doc(user.uid).update({
        'isDriverActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Driver status updated in Firestore: isDriverActive = $isActive');
      }

      // Also update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(KEY_IS_DRIVER_ACTIVE, isActive);

      if (kDebugMode) {
        print('Updated SharedPreferences with is_driver_active = $isActive');
      }

      // Call the status change handler directly (don't wait for listener)
      await onDriverStatusChanged(isActive);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error setting driver active status: $e');
      }
      return false;
    }
  }

  // Check if timer is active
  bool isTimerActive() {
    final isActive = _locationTimer?.isActive ?? false;

    if (kDebugMode) {
      print('Location timer status check: isActive=$isActive');
      if (isActive) {
        print('Current tick: ${_locationTimer!.tick}');
      } else {
        print('Timer is not active');

        // Check if it should be active
        if (_isDriverActive && _isServiceRunning) {
          print(
              'WARNING: Timer should be active but isn\'t! Will restart on next self-check.');
        }
      }
    }

    return isActive;
  }

  // Get current status
  bool isDriverActive() {
    return _isDriverActive;
  }

  // Check if service is running
  bool isServiceRunning() {
    return _isServiceRunning;
  }

  // Force a location update (useful for testing)
  Future<bool> forceLocationUpdate() async {
    try {
      if (kDebugMode) {
        print('Forcing location update...');
      }

      await updateLocationNow();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error forcing location update: $e');
      }
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    if (kDebugMode) {
      print('Disposing DriverLocationService resources');
    }

    _driverStatusSubscription?.cancel();
    _statusCheckTimer?.cancel();
    _locationTimer?.cancel();
    _selfCheckTimer?.cancel();

    _isInitialized = false;
    _isDriverActive = false;
    _isServiceRunning = false;

    if (kDebugMode) {
      print('DriverLocationService disposed');
    }
  }
}
