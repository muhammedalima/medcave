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

// Define notification channel with a consistent ID
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'ambulance_requests', 
  'Ambulance Requests',
  description: 'This channel is used for ambulance request notifications',
  importance: Importance.high,
  playSound: true,
);

// Initialize FlutterLocalNotificationsPlugin as a global instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handle background messages with proper error handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase if not already initialized
    if (!Firebase.apps.any((element) => element.name == '[DEFAULT]')) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    
    if (kDebugMode) {
      print('Handling a background message: ${message.messageId}');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification?.title}');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Error handling background message: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

// Main function with proper error handling
Future<void> main() async {
  try {
    // Ensure Flutter is initialized before using platform channels
    WidgetsFlutterBinding.ensureInitialized();
    
    if (kDebugMode) {
      print('Starting app initialization...');
    }
    
    // Initialize all services
    await initializeServices();
    
    // Run the app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Fatal error during app initialization: $e');
      print('Stack trace: $stackTrace');
    }
    // Show error UI instead of crashing
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize app: $e'),
        ),
      ),
    ));
  }
}

// Comprehensive service initialization with proper sequencing and timeout handling
Future<void> initializeServices() async {
  try {
    if (kDebugMode) {
      print("Starting service initialization...");
    }

    // 1. Initialize Firebase Core with timeout (high priority)
    await _initializeWithTimeout<void>(
      () => Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      'Firebase initialization',
      10, // 10 seconds timeout
    );

    // 2. Set up background message handler early (high priority)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // 3. Request notification permissions (high priority)
    await _requestNotificationPermissions();
    
    // 4. Initialize local notifications (high priority)
    await _initializeLocalNotifications();
    
    // 5. Create notification channel (high priority for Android)
    await _createNotificationChannel();
    
    // 6. Set up foreground message handling (high priority)
    _setupForegroundMessageHandling();

    // Start API service initialization in parallel but don't wait for completion
    _initializeApiServiceInBackground();

    // 7. Initialize background tasks (lower priority)
    try {
      initializeBackgroundTasks();
      if (kDebugMode) {
        print("Background tasks initialized successfully");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Warning: Failed to initialize background tasks: $e");
        print("App will continue without background tasks");
      }
    }

    // 8. Initialize notification service (medium priority)
    await _initializeWithTimeout<void>(
      () => NotificationService().initialize(),
      'Notification service initialization',
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

// Initialize API service in background without blocking app startup
Future<void> _initializeApiServiceInBackground() async {
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

// Helper function to initialize with timeout
Future<T> _initializeWithTimeout<T>(
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
        throw TimeoutException('$operationName timed out after $timeoutSeconds seconds');
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

// Request notification permissions with proper error handling
Future<void> _requestNotificationPermissions() async {
  try {
    // Get messaging instance
    final messaging = FirebaseMessaging.instance;
    
    // Request permission on iOS and newer Android versions
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (kDebugMode) {
      print('Notification permission status: ${settings.authorizationStatus}');
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
Future<void> _initializeLocalNotifications() async {
  try {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
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

// Create notification channel (Android only)
Future<void> _createNotificationChannel() async {
  try {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      if (kDebugMode) {
        print("Notification channel created successfully");
      }
    } else {
      if (kDebugMode) {
        print("Not on Android platform, skipping channel creation");
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print("Error creating notification channel: $e");
      print("App will continue without custom notification channel");
    }
  }
}

// Set up foreground message handling
void _setupForegroundMessageHandling() {
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
        
        flutterLocalNotificationsPlugin.show(
          message.hashCode,
          notification?.title,
          notification?.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android?.smallIcon ?? 'mipmap/ic_launcher',
              // Use high importance for urgent messages
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
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

// Main app widget with error boundary
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'MedCave',
      theme: AppTheme.theme,
      home: const ErrorBoundary(child: Userwrapper()),
    );
  }
}

// Error boundary widget to prevent app crashes from rendering errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  
  const ErrorBoundary({super.key, required this.child});
  
  @override
  ErrorBoundaryState createState() => ErrorBoundaryState();
}

class ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  dynamic error;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset error state when dependencies change
    if (hasError) {
      setState(() {
        hasError = false;
        error = null;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Something went wrong'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'An error occurred in the app.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              if (kDebugMode) Text('Error: $error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hasError = false;
                    error = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    return widget.child;
  }
  
  void catchError(FlutterErrorDetails details) {
    if (kDebugMode) {
      print('Caught error in ErrorBoundary: ${details.exception}');
    }
    setState(() {
      hasError = true;
      error = details.exception;
    });
  }
}

// Custom exception for timeout
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}