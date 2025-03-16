import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medcave/common/googlemapfunction/location_update.dart';
import 'package:medcave/common/services/api_service.dart';
import 'package:medcave/common/services/notification_service.dart';
import 'package:medcave/config/theme/theme.dart';
import 'package:medcave/firebase_options.dart';
import 'package:medcave/Users/UserType/user_wrapper.dart';
import 'package:medcave/common/services/medicine_notification_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define notification channels
const AndroidNotificationChannel ambulanceChannel = AndroidNotificationChannel(
  'ambulance_requests',
  'Ambulance Requests',
  description: 'This channel is used for ambulance request notifications',
  importance: Importance.high,
  playSound: true,
);

const AndroidNotificationChannel medicineChannel = AndroidNotificationChannel(
  'medicine_reminders',
  'Medicine Reminders',
  description: 'This channel is used for medicine reminder notifications',
  importance: Importance.high,
  playSound: true,
);

// Initialize FlutterLocalNotificationsPlugin as a global instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase if not already initialized
    if (!Firebase.apps.any((element) => element.name == '[DEFAULT]')) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
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

    // Show permission screen or main app based on permissions
    runApp(const PermissionHandler());
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

// New Permission Handler Widget
class PermissionHandler extends StatefulWidget {
  const PermissionHandler({super.key});

  @override
  PermissionHandlerState createState() => PermissionHandlerState();
}

class PermissionHandlerState extends State<PermissionHandler> {
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
      await initializeServices();
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

// Fixed service initialization with proper sequencing and timeout handling
Future<void> initializeServices() async {
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

    // 2. Set up background message handler early (high priority)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Initialize local notifications (high priority)
    await _initializeLocalNotifications();

    // 4. Create notification channels (high priority for Android)
    await _createNotificationChannels();

    // 5. Request notification permissions (high priority)
    await _requestNotificationPermissions();

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

    // 9. Initialize the enhanced medicine notification system
    await _initializeWithTimeout<void>(
      () => _initializeMedicineSystem(),
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

// Safe medicine system initialization with proper dependency order
Future<void> _initializeMedicineSystem() async {
  try {
    if (kDebugMode) {
      print("Initializing medicine notification system...");
    }
    
    // 1. Initialize the notification manager first
    final notificationManager = MedicineNotificationManager();
    await notificationManager.init();
    
    // 2. Setup a single global listener for medicine changes
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
void _setupGlobalMedicineListener() {
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
              if (docSnapshot.exists && docSnapshot.data()?.containsKey('reminder') == true) {
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

// Request notification permissions with proper error handling
Future<void> _requestNotificationPermissions() async {
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
Future<void> _createNotificationChannels() async {
  try {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Create ambulance notification channel
      await androidImplementation.createNotificationChannel(ambulanceChannel);

      // Create medicine reminder notification channel
      await androidImplementation.createNotificationChannel(medicineChannel);

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

        // Determine the channel based on message data
        String channelId = message.data['type'] == 'medicine'
            ? medicineChannel.id
            : ambulanceChannel.id;

        String channelName = message.data['type'] == 'medicine'
            ? medicineChannel.name
            : ambulanceChannel.name;

        String channelDesc = message.data['type'] == 'medicine'
            ? medicineChannel.description ?? ''
            : ambulanceChannel.description ?? '';

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