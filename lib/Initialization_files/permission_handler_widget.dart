// File: lib/common/initialization/permission_handler_widget.dart
// Manages permission requests for the app

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medcave/Initialization_files/app_initializer.dart';
import 'package:medcave/main.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerWidget extends StatefulWidget {
  const PermissionHandlerWidget({super.key});

  @override
  PermissionHandlerWidgetState createState() => PermissionHandlerWidgetState();
}

class PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
  bool _permissionsGranted = false;
  bool _isLoading = true;
  List<Permission> _pendingPermissions = [];

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  // Check and request all required permissions
  Future<void> _checkAndRequestPermissions() async {
    try {
      // Define all required permissions from AndroidManifest.xml
      final requiredPermissions = [
        Permission.location,
        Permission.locationAlways, // ACCESS_BACKGROUND_LOCATION
        Permission.microphone, // RECORD_AUDIO
        Permission.notification, // POST_NOTIFICATIONS
        Permission.scheduleExactAlarm, // SCHEDULE_EXACT_ALARM
      ];

      // Check the status of all permissions
      _pendingPermissions = [];

      for (var permission in requiredPermissions) {
        PermissionStatus status = await permission.status;

        if (!status.isGranted) {
          _pendingPermissions.add(permission);
        }
      }

      // If all permissions are granted, proceed with app initialization
      if (_pendingPermissions.isEmpty) {
        await _initializeAppServices();
        setState(() {
          _permissionsGranted = true;
          _isLoading = false;
        });
      } else {
        // Show permissions screen
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permissions: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Request all pending permissions
  Future<void> _requestPermissions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Request each permission one by one for better UX
      for (var permission in _pendingPermissions) {
        await permission.request();
      }

      // Check if all permissions are granted now
      _pendingPermissions = [];
      final requiredPermissions = [
        Permission.location,
        Permission.locationAlways,
        Permission.microphone,
        Permission.notification,
        Permission.scheduleExactAlarm,
      ];

      for (var permission in requiredPermissions) {
        PermissionStatus status = await permission.status;
        if (!status.isGranted) {
          _pendingPermissions.add(permission);
        }
      }

      // If all permissions are granted, proceed with app initialization
      if (_pendingPermissions.isEmpty) {
        await _initializeAppServices();
        setState(() {
          _permissionsGranted = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting permissions: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Initialize app services after permissions are granted
  Future<void> _initializeAppServices() async {
    try {
      await AppInitializer.initializeServices();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing services: $e');
      }
      // We'll still proceed with app launching even if service initialization fails
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking permissions
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing app...'),
              ],
            ),
          ),
        ),
      );
    }

    // If permissions are granted, show the main app
    if (_permissionsGranted) {
      return const MyApp();
    }

    // Show permission request screen
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Permissions Required'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MedCave needs the following permissions to function properly:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionItem(
                      'Location',
                      'Needed to track ambulance and provide emergency services',
                      _pendingPermissions.contains(Permission.location) ||
                          _pendingPermissions
                              .contains(Permission.locationAlways),
                    ),
                    _buildPermissionItem(
                      'Microphone',
                      'Needed for voice communication during emergencies',
                      _pendingPermissions.contains(Permission.microphone),
                    ),
                    _buildPermissionItem(
                      'Notifications',
                      'Needed for ambulance alerts and medicine reminders',
                      _pendingPermissions.contains(Permission.notification),
                    ),
                    _buildPermissionItem(
                      'Schedule Alarms',
                      'Needed for medicine reminders and scheduled notifications',
                      _pendingPermissions
                          .contains(Permission.scheduleExactAlarm),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Grant Permissions',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'These permissions are required for the app to function properly',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build permission item UI
  Widget _buildPermissionItem(
      String title, String description, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRequired ? Icons.error_outline : Icons.check_circle,
            color: isRequired ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}