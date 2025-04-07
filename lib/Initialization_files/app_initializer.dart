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

      // 3. Initialize background tasks (make sure this returns void or Future<void>)
      initializeBackgroundTasks();

      // 4. Create notification channels (high priority for Android)
      await _createNotificationChannels();

      // 5. Request notification permissions (high priority)
      await _requestNotificationPermissions();

      // 6. Set up foreground message handling (high priority)
      _setupForegroundMessageHandling();

      // 7. Initialize FCM token management and register listener for token refreshes
      _initializeFCMTokenManagement();

      // Start API service initialization in parallel but don't wait for completion
      _initializeApiServiceInBackground();

      // 8. Initialize background tasks (lower priority)
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

      // 9. Initialize medicine notification service (high priority)
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

  // Initialize FCM token management
  static void _initializeFCMTokenManagement() {
    try {
      if (kDebugMode) {
        print("Initializing FCM token management...");
      }

      // Register auth state changes to handle token registration when user logs in
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          // User logged in, register current FCM token with server
          await _registerFCMTokenWithServer();
        }
      });

      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
        if (kDebugMode) {
          print("FCM token refreshed: ${newToken.substring(0, 10)}...");
        }

        // Register the new token with our server
        _registerFCMTokenWithServer();
      });

      // Get initial token and register it
      _registerFCMTokenWithServer();

      if (kDebugMode) {
        print("FCM token management initialized successfully");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing FCM token management: $e");
        print("App will continue with limited notification capability");
      }
    }
  }

  // Register FCM token with our server
  static Future<void> _registerFCMTokenWithServer() async {
    try {
      // Check if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print("No user logged in, skipping FCM token registration");
        }
        return;
      }

      // Get current FCM token
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        if (kDebugMode) {
          print("FCM token is null, skipping registration");
        }
        return;
      }

      if (kDebugMode) {
        print(
            "Registering FCM token with server: ${token.substring(0, 10)}...");
      }

      // Create a sanitized driver document in Firestore (if it doesn't exist)
      // This ensures the driver document exists before the server tries to update it
      await _ensureDriverDocumentExists(user.uid);

      // Register token with server
      await ApiService().registerFCMToken(token);

      if (kDebugMode) {
        print("FCM token registered successfully with server");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error registering FCM token with server: $e");
        print("Will retry on next app launch or token refresh");
      }
    }
  }

  // Ensure driver document exists in Firestore
  static Future<void> _ensureDriverDocumentExists(String userId) async {
    try {
      // Reference to driver document
      final driverRef =
          FirebaseFirestore.instance.collection('drivers').doc(userId);

      // Check if the document exists
      final docSnapshot = await driverRef.get();

      if (!docSnapshot.exists) {
        // Create the driver document with default values
        await driverRef.set({
          'isDriverActive': false, // Default to inactive
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          // Don't set FCM token here as it will be set by the server
        });

        if (kDebugMode) {
          print("Created new driver document for user: $userId");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error ensuring driver document exists: $e");
      }
      // Don't throw the error - this is a best-effort operation
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

      // Get FCM token - but don't register it here, we'll do that in _initializeFCMTokenManagement
      final token = await messaging.getToken();
      if (kDebugMode && token != null) {
        if (kDebugMode) {
          print('FCM Token: ${token.substring(0, 10)}...');
        }
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

        // Check if the message contains a serverUrl and update it
        if (message.data.containsKey('serverUrl')) {
          ApiService.updateServerUrlFromNotification(message.data);
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
        // Check if the message contains a serverUrl and update it
        if (message.data.containsKey('serverUrl')) {
          ApiService.updateServerUrlFromNotification(message.data);
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
