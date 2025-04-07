import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medcave/Initialization_files/notification_channels.dart';
import 'package:medcave/main/features/ambulance_tracking/presentation/pages/driver/details_ambulancedriver.dart';
import 'package:medcave/main/features/ambulance_tracking/presentation/pages/driver/driverwrapper.dart';
import 'dart:async';

import 'package:medcave/common/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Flag to track initialization status
  bool _isInitialized = false;

  // Rate limiting for background tasks
  DateTime? _lastCheckDriverStatusTime;
  static const Duration _minimumCheckInterval = Duration(minutes: 10);

  // Error tracking to prevent continuous retries
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;
  DateTime? _lastErrorTime;
  static const Duration _errorCooldownPeriod = Duration(hours: 1);

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Global navigator key for navigation from service
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Stream controller for notification updates
  static final StreamController<RemoteMessage> _notificationStreamController =
      StreamController<RemoteMessage>.broadcast();

  // Stream of notifications for listening in the app
  static Stream<RemoteMessage> get notificationStream =>
      _notificationStreamController.stream;

  Future<void> initialize() async {
    // Prevent double initialization
    if (_isInitialized) {
      if (kDebugMode) {
        print('NotificationService already initialized, skipping...');
      }
      return;
    }

    try {
      // Request permission for iOS
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Clear error state on initialization
      await _resetErrorState();

      // Start FCM token handling in background - with rate limiting
      _saveFcmTokenInBackground();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle message opened app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check for initial message (app opened from terminated state)
      _checkInitialMessage();

      // Mark as initialized
      _isInitialized = true;

      if (kDebugMode) {
        print('NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
      // Don't mark as initialized on error so we can retry later
    }
  }

  // Reset error tracking state
  Future<void> _resetErrorState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_driver_status_check');
      await prefs.remove('consecutive_errors');
      await prefs.remove('last_error_time');
      _consecutiveErrors = 0;
      _lastErrorTime = null;
      _lastCheckDriverStatusTime = null;
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting error state: $e');
      }
    }
  }

  // Check if a driver status operation should be rate-limited
  Future<bool> _shouldRateLimitDriverStatusCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load previous state
      final lastCheckTimeStr = prefs.getString('last_driver_status_check');
      if (lastCheckTimeStr != null) {
        _lastCheckDriverStatusTime = DateTime.parse(lastCheckTimeStr);
      }
      
      _consecutiveErrors = prefs.getInt('consecutive_errors') ?? 0;
      
      final lastErrorTimeStr = prefs.getString('last_error_time');
      if (lastErrorTimeStr != null) {
        _lastErrorTime = DateTime.parse(lastErrorTimeStr);
      }

      final now = DateTime.now();

      // If we've had too many errors and we're still in cooldown period
      if (_consecutiveErrors >= _maxConsecutiveErrors && 
          _lastErrorTime != null &&
          now.difference(_lastErrorTime!) < _errorCooldownPeriod) {
        if (kDebugMode) {
          print('Rate limiting due to too many consecutive errors');
        }
        return true;
      }

      // Check time-based rate limit
      if (_lastCheckDriverStatusTime != null) {
        final timeSinceLastCheck = now.difference(_lastCheckDriverStatusTime!);
        if (timeSinceLastCheck < _minimumCheckInterval) {
          if (kDebugMode) {
            print('Rate limiting driver status check: too frequent');
          }
          return true;
        }
      }

      // Update the last check time
      _lastCheckDriverStatusTime = now;
      await prefs.setString('last_driver_status_check', now.toIso8601String());

      // Not rate limited
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error in rate limiting check: $e');
      }
      // Default to not rate limited on error
      return false;
    }
  }

  // Record a driver status check error
  Future<void> _recordDriverStatusCheckError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Increment error count
      _consecutiveErrors++;
      await prefs.setInt('consecutive_errors', _consecutiveErrors);
      
      // Record error time
      _lastErrorTime = DateTime.now();
      await prefs.setString('last_error_time', _lastErrorTime!.toIso8601String());
      
      if (kDebugMode) {
        print('Recorded driver status check error: $_consecutiveErrors consecutive errors');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording driver status error: $e');
      }
    }
  }

  // Reset consecutive errors on success
  Future<void> _recordDriverStatusCheckSuccess() async {
    try {
      if (_consecutiveErrors > 0) {
        final prefs = await SharedPreferences.getInstance();
        _consecutiveErrors = 0;
        await prefs.setInt('consecutive_errors', 0);
        
        if (kDebugMode) {
          print('Reset consecutive errors after successful check');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording driver status success: $e');
      }
    }
  }

  // Initialize local notifications separately
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Create notification channels for Android
      AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Use the pre-defined channels from NotificationChannels class
        await androidImplementation.createNotificationChannel(
            NotificationChannels.ambulanceChannel);
        await androidImplementation.createNotificationChannel(
            NotificationChannels.medicineChannel);
            
        if (kDebugMode) {
          print("Notification channels created successfully");
        }
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Only report as an issue if we're on Android
        if (kDebugMode) {
          print(
              "Warning: Android implementation not available even though we're on Android");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing local notifications: $e");
      }
      // Don't rethrow - we want to continue even if notifications fail
    }
  }

  // Check initial message in background
  void _checkInitialMessage() {
    // Don't block initialization on this
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? initialMessage) {
      if (initialMessage != null) {
        _handleInitialMessage(initialMessage);
      }
    }).catchError((e) {
      if (kDebugMode) {
        print("Error getting initial message: $e");
      }
    });
  }

  // Save FCM token in the background to avoid blocking the UI
  void _saveFcmTokenInBackground() {
    // Fire and forget - don't await
    _saveFcmTokenWithErrorHandling().then((_) {
      if (kDebugMode) {
        print("FCM token handling completed in background");
      }
    }).catchError((e) {
      if (kDebugMode) {
        print("Error in background FCM token handling: $e");
      }
    });

    // Setup token refresh listener
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('FCM token refreshed: ${newToken.substring(0, 10)}...');
      }
      _saveFcmTokenWithErrorHandling();
    });
  }

  Future<void> _saveFcmTokenWithErrorHandling() async {
    try {
      // Check if we should rate limit this operation
      if (await _shouldRateLimitDriverStatusCheck()) {
        return;
      }

      if (kDebugMode) {
        print("Attempting to get FCM token...");
      }

      // Wait to ensure Firebase is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      String? token;
      try {
        token = await _firebaseMessaging.getToken();
        if (kDebugMode) {
          print("FCM token retrieved successfully");
        }
      } catch (tokenError) {
        if (kDebugMode) {
          print("Error getting FCM token: $tokenError");
        }
        await _recordDriverStatusCheckError();
        // Wait and try again after a short delay
        await Future.delayed(const Duration(seconds: 2));
        try {
          token = await _firebaseMessaging.getToken();
          if (kDebugMode) {
            print("FCM token retrieved on second attempt");
          }
        } catch (retryError) {
          if (kDebugMode) {
            print("Failed to get FCM token after retry: $retryError");
          }
          await _recordDriverStatusCheckError();
          return; // Exit the function if we can't get a token
        }
      }

      // Skip the rest if token is null or empty
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('Warning: FCM token is null or empty');
        }
        await _recordDriverStatusCheckError();
        return;
      }

      if (kDebugMode) {
        print('FCM Token obtained: ${token.substring(0, 10)}...');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Save FCM token in shared preferences first (as a backup)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', token);

          // First, get the current driver document to check existing status
          DocumentSnapshot driverDoc = await FirebaseFirestore.instance
              .collection('drivers')
              .doc(user.uid)
              .get();

          if (driverDoc.exists) {
            // Update while preserving the existing isDriverActive status
            Map<String, dynamic> driverData =
                driverDoc.data() as Map<String, dynamic>;
            bool currentActiveStatus = driverData['isDriverActive'] ?? false;

            await FirebaseFirestore.instance
                .collection('drivers')
                .doc(user.uid)
                .update({
              'fcmToken': token,
              // Preserve existing driver active status, not forcing it to true
              'isDriverActive': currentActiveStatus,
              'deviceInfo': {
                'platform': kIsWeb ? 'web' : defaultTargetPlatform.toString(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              'updatedAt': FieldValue.serverTimestamp(),
              'lastStatusCheck': FieldValue.serverTimestamp(),
            });

            if (kDebugMode) {
              print(
                  'FCM Token updated in Firestore while preserving driver status');
            }
          } else {
            // Document doesn't exist, create it with isDriverActive set to false by default
            if (kDebugMode) {
              print('Driver document does not exist, creating new one...');
            }

            // Get user location if available or use default
            final prefs = await SharedPreferences.getInstance();
            final lat = prefs.getDouble('last_latitude') ?? 37.4221;
            final lng = prefs.getDouble('last_longitude') ?? -122.0841;

            try {
              await FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(user.uid)
                  .set({
                'fcmToken': token,
                'isDriverActive':
                    false, // Set to false by default for new drivers
                'userId': user.uid,
                'email': user.email,
                'displayName': user.displayName ?? 'Driver',
                'phoneNumber': user.phoneNumber,
                'location': {
                  'latitude': lat,
                  'longitude': lng,
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                'deviceInfo': {
                  'platform': kIsWeb ? 'web' : defaultTargetPlatform.toString(),
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
                'lastStatusCheck': FieldValue.serverTimestamp(),
              });

              if (kDebugMode) {
                print(
                    'Created new driver document with FCM token and inactive status');
              }
            } catch (innerError) {
              if (kDebugMode) {
                print('Error creating driver document: $innerError');
              }
              await _recordDriverStatusCheckError();
            }
          }
          
          // Operation succeeded, reset error count
          await _recordDriverStatusCheckSuccess();
          
          // Register FCM token with server using ApiService
          try {
            await ApiService().registerFCMToken(token);
            if (kDebugMode) {
              print('FCM token registered with server');
            }
          } catch (apiError) {
            if (kDebugMode) {
              print('Error registering FCM token with server: $apiError');
              print('Will continue as token is already saved in Firestore');
            }
          }
          
        } catch (e) {
          if (kDebugMode) {
            print('Error saving FCM token to Firestore: $e');
          }
          await _recordDriverStatusCheckError();

          // Save token to shared preferences as fallback
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', token);
        }
      } else {
        if (kDebugMode) {
          print('Cannot save FCM token to Firestore: User not logged in');

          // Save token to shared preferences anyway for later use
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', token);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _saveFcmTokenWithErrorHandling: $e');
      }
      await _recordDriverStatusCheckError();
    }
  }

  // Store notification for displaying in the notifications screen
  Future<void> _storeNotificationForHistory(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current stored notifications or initialize empty list
      final String notificationsJson =
          prefs.getString('notification_history') ?? '[]';
      List<dynamic> notifications = [];
      try {
        notifications = jsonDecode(notificationsJson);
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding notification history, starting fresh: $e');
        }
        // If there's a JSON error, start with an empty list
        notifications = [];
      }

      // Determine notification type
      String type = 'general';
      final data = message.data;
      final notification = message.notification;

      // Try to detect notification type from various sources
      if (data.containsKey('type')) {
        type = data['type'];
      } else if (data.containsKey('requestId')) {
        type = 'ambulance_request';
      } else if (notification?.title != null) {
        final title = notification!.title!.toLowerCase();
        if (title.contains('medicine') ||
            title.contains('medication') ||
            title.contains('dose') ||
            title.contains('tablet') ||
            title.contains('pill')) {
          type = 'medication';
        } else if (title.contains('appointment') ||
            title.contains('doctor') ||
            title.contains('visit') ||
            title.contains('checkup')) {
          type = 'appointment';
        } else if (title.contains('emergency') ||
            title.contains('accident') ||
            title.contains('urgent')) {
          type = 'emergency';
        }
      }

      // Create a notification record
      final Map<String, dynamic> notificationRecord = {
        'id': message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'New Notification',
        'body': message.notification?.body,
        'time': DateTime.now().toIso8601String(),
        'data': message.data,
        'type': type,
      };

      // Add to the beginning of the list (newest first)
      notifications.insert(0, notificationRecord);

      // Limit the history to 100 notifications to prevent excessive storage
      if (notifications.length > 100) {
        notifications = notifications.sublist(0, 100);
      }

      // Store back in SharedPreferences
      await prefs.setString('notification_history', jsonEncode(notifications));

      if (kDebugMode) {
        print('Stored notification in history: ${notificationRecord['title']}');
      }

      // Add to the stream for real-time updates
      _notificationStreamController.add(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error storing notification history: $e');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      // Store notification in history for the notification screen
      await _storeNotificationForHistory(message);

      // Check if message contains server URL and update if needed
      if (message.data.containsKey('serverUrl')) {
        ApiService.updateServerUrlFromNotification(message.data);
      }

      // For ambulance requests, show a notification with action buttons
      if (message.data.containsKey('requestId') &&
          message.data['type'] == 'ambulance_request') {
        final String requestId = message.data['requestId'];

        // Create action buttons for Android
        final List<AndroidNotificationAction> actions = [
          const AndroidNotificationAction(
            'accept_action',
            'Accept',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'reject_action',
            'Reject',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ];

        // Create the Android notification details with actions
        final AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          NotificationChannels.ambulanceChannel.id,
          NotificationChannels.ambulanceChannel.name,
          channelDescription: NotificationChannels.ambulanceChannel.description ?? '',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          actions: actions,
        );

        // Use standard iOS notification details
        const DarwinNotificationDetails iOSPlatformChannelSpecifics =
            DarwinNotificationDetails();

        final NotificationDetails platformChannelSpecifics =
            NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );

        // Show the notification with action buttons
        await _flutterLocalNotificationsPlugin.show(
          requestId.hashCode, // Use requestId hash as notification ID to avoid duplicates
          message.notification?.title ?? 'New Ambulance Request',
          message.notification?.body ?? 'You have a new ambulance request',
          platformChannelSpecifics,
          payload: jsonEncode({
            ...message.data,
            'navigation': 'ambulance_detail',
          }),
        );
      } else if (message.notification != null) {
        // For other notifications, show standard notification
        await _showNotification(
          message.notification!.title ?? 'New Notification',
          message.notification!.body ?? 'You have a new message',
          message.data,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling foreground message: $e');
      }
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    try {
      if (kDebugMode) {
        print('Message opened app: ${message.data}');
      }

      // Store notification in history
      _storeNotificationForHistory(message);

      // Update server URL if it's included in the notification
      if (message.data.containsKey('serverUrl')) {
        ApiService.updateServerUrlFromNotification(message.data);
      }

      // Handle navigation based on the notification data
      _handleNotificationNavigation(message.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling message opened app: $e');
      }
    }
  }

  void _handleInitialMessage(RemoteMessage message) {
    try {
      if (kDebugMode) {
        print('App opened from terminated state with message: ${message.data}');
      }

      // Store notification in history
      _storeNotificationForHistory(message);

      // Update server URL if it's included in the notification
      if (message.data.containsKey('serverUrl')) {
        ApiService.updateServerUrlFromNotification(message.data);
      }

      // Handle navigation based on the notification data
      _handleNotificationNavigation(message.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling initial message: $e');
      }
    }
  }

  Future<void> _showNotification(
      String title, String body, Map<String, dynamic> payload) async {
    try {
      // Log before attempting to show notification
      if (kDebugMode) {
        print("Attempting to show notification: $title");
      }

      // Determine which channel to use based on the notification content
      String channelId;
      String channelName;
      String channelDesc;
      
      // Determine the channel based on payload or title content
      if (payload.containsKey('type') && payload['type'] == 'medication' ||
          title.toLowerCase().contains('medicine') ||
          title.toLowerCase().contains('medication')) {
        // Use medicine channel
        channelId = NotificationChannels.medicineChannel.id;
        channelName = NotificationChannels.medicineChannel.name;
        channelDesc = NotificationChannels.medicineChannel.description ?? '';
      } else {
        // Default to ambulance channel
        channelId = NotificationChannels.ambulanceChannel.id;
        channelName = NotificationChannels.ambulanceChannel.name;
        channelDesc = NotificationChannels.ambulanceChannel.description ?? '';
      }

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
          
      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), // Dynamic ID
        title,
        body,
        platformChannelSpecifics,
        payload: jsonEncode(payload),
      );
      if (kDebugMode) {
        print("Notification shown successfully");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error showing notification: $e");
      }
    }
  }

  void _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    try {
      final String? payload = notificationResponse.payload;
      if (payload == null) return;

      if (kDebugMode) {
        print('Notification response received: $payload');
        print('Action ID: ${notificationResponse.actionId}');
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(payload);
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding notification payload: $e');
        }
        return;
      }

      // Update server URL if included
      if (data.containsKey('serverUrl')) {
        ApiService.updateServerUrlFromNotification(data);
      }

      // Handle different actions
      if (notificationResponse.actionId == 'accept_action') {
        _handleAcceptAction(data);
      } else if (notificationResponse.actionId == 'reject_action') {
        _handleRejectAction(data);
      } else {
        // Normal notification tap - handle navigation
        _handleNotificationNavigation(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing notification response: $e');
      }
    }
  }

  // Handle accept action
  Future<void> _handleAcceptAction(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('requestId')) return;

      final String requestId = data['requestId'];
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          print('Error: User not authenticated');
        }
        return;
      }

      // Get current location with error handling
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5));
      } catch (e) {
        if (kDebugMode) {
          print('Error getting location: $e, using default');
        }
        // Use default location if we can't get the current one
        position = Position(
            latitude: 0,
            longitude: 0,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0);
      }

      // Update the request status in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('ambulanceRequests')
            .doc(requestId)
            .update({
          'status': 'accepted',
          'assignedDriverId': currentUser.uid,
          'driverName': currentUser.displayName ?? 'Current Driver',
          'acceptedTime': Timestamp.now(),
          'estimatedArrivalTime': '10 minutes', // This should be calculated
          'startingLocation': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': position.heading,
            'speed': position.speed,
            'accuracy': position.accuracy,
            'timestamp': FieldValue.serverTimestamp(),
          }
        });

        if (kDebugMode) {
          print('Request accepted successfully: $requestId');
        }

        // Navigate to the driver wrapper screen
        _navigateToDriverWrapper();
      } catch (e) {
        if (kDebugMode) {
          print('Error updating Firestore for accepted request: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting request from notification: $e');
      }
    }
  }

  // Handle reject action
  Future<void> _handleRejectAction(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('requestId')) return;

      final String requestId = data['requestId'];
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          print('Error: User not authenticated');
        }
        return;
      }

      // Update Firestore
      try {
        await FirebaseFirestore.instance
            .collection('ambulanceRequests')
            .doc(requestId)
            .update({
          'status': 'available', // Reset to available for other drivers
          'rejectedBy':
              FieldValue.arrayUnion([currentUser.uid]), // Track who rejected
        });

        if (kDebugMode) {
          print('Request rejected: $requestId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error updating Firestore for rejected request: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting request from notification: $e');
      }
    }
  }

  // Navigate to driver wrapper after accepting a request
  void _navigateToDriverWrapper() {
    try {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => const AmbulanceDriverWrapper(),
          ),
        );
      } else {
        if (kDebugMode) {
          print('Navigator key is null, cannot navigate');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to driver wrapper: $e');
      }
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      if (data.containsKey('requestId') &&
          (data.containsKey('type') && data['type'] == 'ambulance_request' ||
              data.containsKey('navigation') &&
                  data['navigation'] == 'ambulance_detail')) {
        final String requestId = data['requestId'];

        // Fetch complete data for the request
        _fetchRequestDataAndNavigate(requestId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification navigation: $e');
      }
    }
  }

  // Fetch request data and navigate to detail page
  Future<void> _fetchRequestDataAndNavigate(String requestId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ambulanceRequests')
          .doc(requestId)
          .get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('Request document not found: $requestId');
        }
        return;
      }

      final Map<String, dynamic> completeData = {
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      };

      // Navigate to detail page
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => AmbulanceDetailDriver(
              completeData: completeData,
              requestId: requestId,
              isPastRide: false,
            ),
          ),
        );
      } else {
        if (kDebugMode) {
          print('Navigator key is null, cannot navigate to details');
        }
      }

      if (kDebugMode) {
        print('Navigating to request details for ID: $requestId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching request data: $e');
      }
    }
  }

  // Get notification history from storage
  static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notification_history') ?? '[]';

      List<dynamic> notifications = [];
      try {
        notifications = jsonDecode(notificationsJson);
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding notification history: $e');
        }
        return [];
      }

      // Convert to List<Map<String, dynamic>> and parse datetime
      return notifications.map<Map<String, dynamic>>((item) {
        try {
          // Parse the ISO date string back to DateTime
          final DateTime time = DateTime.parse(item['time']);
          return {
            ...item,
            'time': time,
          };
        } catch (e) {
          // If time parsing fails, use current time
          return {
            ...item,
            'time': DateTime.now(),
          };
        }
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification history: $e');
      }
      return [];
    }
  }

  // Clear notification history
  static Future<void> clearNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_history', '[]');
      if (kDebugMode) {
        print('Notification history cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing notification history: $e');
      }
    }
  }

  // Delete a single notification by ID
  static Future<void> deleteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notification_history') ?? '[]';

      List<dynamic> notifications = [];
      try {
        notifications = jsonDecode(notificationsJson);

        // Remove the notification with matching ID
        notifications.removeWhere((item) => item['id'] == id);

        // Save back to storage
        await prefs.setString(
            'notification_history', jsonEncode(notifications));
        if (kDebugMode) {
          print('Notification deleted: $id');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting notification: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error accessing notification storage: $e');
      }
    }
  }

  // Cleanup resources
  void dispose() {
    // Close stream controller if open
    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.close();
    }
  }
}

// Background message handler with rate limiting
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase if not already initialized
    await Firebase.initializeApp();

    if (kDebugMode) {
      print('Handling a background message: ${message.messageId}');
    }

    // Rate limiting for background tasks
    final prefs = await SharedPreferences.getInstance();
    final lastCheckStr = prefs.getString('last_driver_status_check');
    final now = DateTime.now();
    
    // Apply rate limiting to background handlers
    if (lastCheckStr != null) {
      final lastCheck = DateTime.parse(lastCheckStr);
      final timeSince = now.difference(lastCheck);
      
      // If we checked too recently, skip this execution
      if (timeSince < const Duration(minutes: 10)) {
        if (kDebugMode) {
          print('Rate limiting background task - checked too recently');
        }
        return;
      }
    }
    
    // Update last check time
    await prefs.setString('last_driver_status_check', now.toIso8601String());

    // Store notification for history even in background
    try {
      final notificationsJson = prefs.getString('notification_history') ?? '[]';
      List<dynamic> notifications = [];
      try {
        notifications = jsonDecode(notificationsJson);
      } catch (e) {
        // If there's a JSON error, start with an empty list
        notifications = [];
      }

      // Determine notification type
      String type = message.data['type'] ?? 'general';
      final notification = message.notification;

      // Create notification record with minimal data
      final Map<String, dynamic> notificationRecord = {
        'id': message.messageId ?? now.millisecondsSinceEpoch.toString(),
        'title': notification?.title ?? 'New Notification',
        'body': notification?.body,
        'time': now.toIso8601String(), 
        'type': type,
      };

      // Add to the beginning of the list (newest first)
      notifications.insert(0, notificationRecord);

      // Limit the history to 100 notifications
      if (notifications.length > 100) {
        notifications = notifications.sublist(0, 100);
      }

      // Store back in SharedPreferences
      await prefs.setString('notification_history', jsonEncode(notifications));
    } catch (e) {
      if (kDebugMode) {
        print('Error storing notification in background handler: $e');
      }
    }

    // Check for server URL in the notification and save it
    if (message.data.containsKey('serverUrl')) {
      final String serverUrl = message.data['serverUrl'];
      if (serverUrl.isNotEmpty) {
        try {
          await prefs.setString('server_url', serverUrl);
          if (kDebugMode) {
            print('Saved server URL from background message');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error saving server URL in background handler: $e');
          }
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error in background message handler: $e');
    }
    // Don't rethrow - this would crash the app in the background
  }
}