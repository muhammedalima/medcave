// File: lib/common/initialization/app_initializer.dart
// Updated to initialize MedicineNotificationService

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medcave/Initialization_files/background_tasks.dart';
import 'package:medcave/Initialization_files/notification_channels.dart';
import 'package:medcave/common/services/api_service.dart';
import 'package:medcave/common/services/medicine_notification_service.dart';
import 'package:medcave/firebase_options.dart';
import 'package:medcave/common/services/medicine_notification_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Global instance for notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class AppInitializer {
  // Initialize all app services
  static Future<void> initializeServices() async {
    try {
      if (kDebugMode) {
        print("Starting service initialization...");
      }

      // 1. Initialize Firebase Core with timeout (high priority)
      await _initializeWithTimeout<void>(
        () => Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform),
        'Firebase initialization',
        10, // 10 seconds timeout
      );

      // 2. Initialize local notifications (high priority)
      await _initializeLocalNotifications();

      // 3. Create notification channels (high priority for Android)
      await _createNotificationChannels();

      // 4. Request notification permissions (high priority)
      await _requestNotificationPermissions();

      // 5. Set up foreground message handling (high priority)
      _setupForegroundMessageHandling();

      // Start API service initialization in parallel but don't wait for completion
      _initializeApiServiceInBackground();

      // 6. Initialize background tasks (lower priority)
      try {
        BackgroundTasks.initialize();
        if (kDebugMode) {
          print("Background tasks initialized successfully");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Warning: Failed to initialize background tasks: $e");
          print("App will continue without background tasks");
        }
      }

      // 7. Initialize medicine notification service (high priority)
      await _initializeWithTimeout<void>(
        () => _initializeMedicineNotificationSystem(),
        'Medicine notification system initialization',
        5, // 5 seconds timeout
      );

      if (kDebugMode) {
        print("Critical services initialized successfully");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error during service initialization: $e");
        print("Stack trace: $stackTrace");
      }
      // Rethrow to be caught in main
      rethrow;
    }
  }

  // Initialize medicine notification system
  static Future<void> _initializeMedicineNotificationSystem() async {
    try {
      if (kDebugMode) {
        print("Initializing medicine notification system...");
      }

      // 1. Initialize the MedicineNotificationService first
      // Create an instance and initialize it
      final notificationService = MedicineNotificationService();
      await notificationService.initialize();

      if (kDebugMode) {
        print("MedicineNotificationService initialized");
      }

      // 2. Initialize the MedicineNotificationManager which depends on the service
      final notificationManager = MedicineNotificationManager();
      await notificationManager.init();

      if (kDebugMode) {
        print("MedicineNotificationManager initialized");
      }

      // 3. Setup a single global listener for medicine changes
      _setupGlobalMedicineListener();

      if (kDebugMode) {
        print("Medicine notification system initialized successfully");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing medicine notification system: $e");
      }
    }
  }

  // Set up a single global listener for medicine and reminder changes
  static void _setupGlobalMedicineListener() {
    try {
      // Listen for user authentication state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          final userId = user.uid;

          // 1. Create a single listener for medicine collection changes
          FirebaseFirestore.instance
              .collection('userdata')
              .doc(userId)
              .collection('medicines')
              .snapshots()
              .listen((_) {
            // Use a significant debounce to prevent rapid refreshes
            Future.delayed(const Duration(milliseconds: 1000), () {
              // Only refresh if user is still logged in
              if (FirebaseAuth.instance.currentUser?.uid == userId) {
                MedicineNotificationManager().refreshNotifications();
              }
            });
          });

          // 2. Create a single listener for reminder data changes
          FirebaseFirestore.instance
              .collection('userdata')
              .doc(userId)
              .snapshots()
              .listen((docSnapshot) {
            if (docSnapshot.exists &&
                docSnapshot.data()?.containsKey('reminder') == true) {
              // Use a significant debounce to prevent rapid refreshes
              Future.delayed(const Duration(milliseconds: 1000), () {
                // Only refresh if user is still logged in
                if (FirebaseAuth.instance.currentUser?.uid == userId) {
                  MedicineNotificationManager().refreshNotifications();
                }
              });
            }
          });
        }
      });

      if (kDebugMode) {
        print("Global medicine listener setup successfully");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error setting up global medicine listener: $e");
      }
    }
  }

  // Helper function to initialize with timeout
  static Future<T> _initializeWithTimeout<T>(
    Future<T> Function() initFunction,
    String operationName,
    int timeoutSeconds,
  ) async {
    try {
      if (kDebugMode) {
        print("Starting $operationName...");
      }

      final result = await initFunction().timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          throw TimeoutException(
              '$operationName timed out after $timeoutSeconds seconds');
        },
      );

      if (kDebugMode) {
        print("$operationName completed successfully");
      }

      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error during $operationName: $e");
        print("Stack trace: $stackTrace");
      }
      rethrow;
    }
  }

  // Initialize API service in background without blocking app startup
  static Future<void> _initializeApiServiceInBackground() async {
    try {
      if (kDebugMode) {
        print("Starting API service initialization in background");
      }
      // Fire and forget - don't await this
      ApiService.initialize().then((_) {
        if (kDebugMode) {
          print("API service initialized successfully in background");
        }
      }).catchError((e) {
        if (kDebugMode) {
          print("Error initializing API service in background: $e");
          print("App will continue with default server settings");
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error setting up background API initialization: $e");
      }
      // Don't rethrow - this should never block app startup
    }
  }

  // Request notification permissions with proper error handling
  static Future<void> _requestNotificationPermissions() async {
    try {
      // Get messaging instance
      final messaging = FirebaseMessaging.instance;

      // Request permission on iOS and newer Android versions
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print(
            'Notification permission status: ${settings.authorizationStatus}');
      }

      // Get FCM token
      final token = await messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
        print('App will continue without notification permissions');
      }
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode) {
            print("Notification response received: ${response.payload}");
          }
          // Handle notification tap here
        },
      );

      if (kDebugMode) {
        print("Local notifications plugin initialized");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing local notifications: $e");
        print("App will continue without local notifications");
      }
    }
  }

  // Create notification channels (Android only)
  static Future<void> _createNotificationChannels() async {
    try {
      final androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Create ambulance notification channel
        await androidImplementation
            .createNotificationChannel(NotificationChannels.ambulanceChannel);

        // Create medicine reminder notification channel
        await androidImplementation
            .createNotificationChannel(NotificationChannels.medicineChannel);

        if (kDebugMode) {
          print("Notification channels created successfully");
        }
      } else {
        if (kDebugMode) {
          print("Not on Android platform, skipping channel creation");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error creating notification channels: $e");
        print("App will continue without custom notification channels");
      }
    }
  }

  // Set up foreground message handling
  static void _setupForegroundMessageHandling() {
    try {
      // Handle messages when the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Received foreground message: ${message.messageId}');
          print('Message data: ${message.data}');
          print('Message notification: ${message.notification?.title}');
        }

        // Show a local notification if message contains a notification
        if (message.notification != null) {
          final notification = message.notification;
          final android = message.notification?.android;

          // Determine the channel based on message data
          String channelId = message.data['type'] == 'medicine'
              ? NotificationChannels.medicineChannel.id
              : NotificationChannels.ambulanceChannel.id;

          String channelName = message.data['type'] == 'medicine'
              ? NotificationChannels.medicineChannel.name
              : NotificationChannels.ambulanceChannel.name;

          String channelDesc = message.data['type'] == 'medicine'
              ? NotificationChannels.medicineChannel.description ?? ''
              : NotificationChannels.ambulanceChannel.description ?? '';

          flutterLocalNotificationsPlugin.show(
            message.hashCode,
            notification?.title,
            notification?.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channelId,
                channelName,
                channelDescription: channelDesc,
                icon: android?.smallIcon ?? 'mipmap/ic_launcher',
                // Use high importance for urgent messages
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            payload: message.data.toString(),
          );

          // Also add to MedicineNotificationService history if it's a medicine notification
          if (message.data['type'] == 'medicine' ||
              message.data['type'] == 'medication') {
            MedicineNotificationService.addNotificationToHistory(
                title: notification?.title ?? 'Medicine Reminder',
                body: notification?.body ?? '',
                type: 'medication',
                data: message.data);
          }
        }
      });

      // Handle notification opens when app is in background but not terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Message opened from background state: ${message.messageId}');
        }
        // Handle notification tap when app in background
      });

      if (kDebugMode) {
        print("Foreground message handling set up successfully");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error setting up foreground message handling: $e");
        print("App will continue without foreground message handling");
      }
    }
  }
}

// Custom exception for timeout
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
