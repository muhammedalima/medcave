import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medcave/common/googlemapfunction/location_update.dart';
import 'package:medcave/common/pushnotification/api_service.dart';
import 'package:medcave/common/pushnotification/notification_service.dart';
import 'package:medcave/config/theme/theme.dart';
import 'package:medcave/firebase_options.dart';
import 'package:medcave/Users/UserType/user_wrapper.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'ambulance_requests', // same as in server code
  'Ambulance Requests',
  description: 'This channel is used for ambulance request notifications',
  importance: Importance.high,
  playSound: true,
);

// Initialize FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
}

// Improved service initialization with proper order and error handling
// Improved service initialization with proper order and error handling
Future<void> initializeServices() async {
  try {
    if (kDebugMode) {
      print("Starting service initialization...");
    }

    // First initialize Firebase core (skip if already initialized in main)
    if (!Firebase.apps.any((element) => element.name == '[DEFAULT]')) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    if (kDebugMode) {
      print("Firebase initialized successfully");
    }

    // Initialize background tasks
    initializeBackgroundTasks();
    if (kDebugMode) {
      print("Background tasks initialized successfully");
    }

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    if (kDebugMode) {
      print("Background message handler registered");
    }

    // Add a small delay to ensure Firebase services are ready
    await Future.delayed(Duration(milliseconds: 500));

    // Properly initialize the local notifications plugin first
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
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
      },
    );
    if (kDebugMode) {
      print("Local notifications plugin initialized");
    }

    // AFTER initialization, create the channel - FIXED SYNTAX HERE
    try {
      AndroidFlutterLocalNotificationsPlugin? androidImplementation = 
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
              
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
        if (kDebugMode) {
          print("Notification channel created successfully");
        }
      } else {
        if (kDebugMode) {
          print("Android implementation not available, skipping channel creation");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error creating notification channel: $e");
      }
    }

    // Then initialize your ApiService
    await ApiService.initialize();
    if (kDebugMode) {
      print("ApiService initialized successfully");
    }

    // Finally initialize notifications service
    // Note: Make sure NotificationService doesn't try to initialize flutterLocalNotificationsPlugin again
    await NotificationService().initialize();
    if (kDebugMode) {
      print("NotificationService initialized successfully");
    }

    if (kDebugMode) {
      print("All services initialized successfully");
    }
  } catch (e) {
    if (kDebugMode) {
      print("Error during service initialization: $e");
    }
  }
}

Future<void> main() async {
  // This must be called before anything that might use platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Use the comprehensive service initialization
  await initializeServices();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey, // Use the global navigator key
      title: 'MedCave',
      theme: AppTheme.theme,
      home: const Userwrapper(),
    );
  }
}