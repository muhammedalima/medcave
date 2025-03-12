import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/details_ambulancedriver.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/driverwrapper.dart';
import 'dart:async';

import 'package:medcave/common/pushnotification/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Global navigator key for navigation from service
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'ambulance_requests',
    'Ambulance Requests',
    description: 'This channel is used for ambulance request notifications.',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
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

    // Configure Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
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

    // Create notification channel for Android - FIXED SYNTAX HERE
    try {
      AndroidFlutterLocalNotificationsPlugin? androidImplementation = 
          _flutterLocalNotificationsPlugin
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

    // Get and save FCM token with improved error handling
    await _saveFcmTokenWithErrorHandling();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle message opened app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app opened from terminated state)
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
  }

  Future<void> _saveFcmTokenWithErrorHandling() async {
    try {
      if (kDebugMode) {
        print("Attempting to get FCM token...");
      }
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
        // Wait and try again after a short delay
        await Future.delayed(Duration(seconds: 2));
        try {
          token = await _firebaseMessaging.getToken();
          if (kDebugMode) {
            print("FCM token retrieved on second attempt");
          }
        } catch (retryError) {
          if (kDebugMode) {
            print("Failed to get FCM token after retry: $retryError");
          }
          return; // Exit the function if we can't get a token
        }
      }

      // Skip the rest if token is null or empty
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('Warning: FCM token is null or empty');
        }
        return;
      }

      if (kDebugMode) {
        print('FCM Token obtained: $token');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Try to update the driver document
          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(user.uid)
              .update({
            'fcmToken': token,
            'isDriverActive': true,
            'deviceInfo': {
              'platform': kIsWeb ? 'web' : defaultTargetPlatform.toString(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (kDebugMode) {
            print('FCM Token updated: $token');
          }
        } catch (e) {
          // If document doesn't exist, create it
          if (e.toString().contains('No document to update')) {
            if (kDebugMode) {
              print('Driver document does not exist, creating new one...');
            }

            // Get user location if available or use default
            final prefs = await SharedPreferences.getInstance();
            final lat = prefs.getDouble('last_latitude') ?? 37.4221;
            final lng = prefs.getDouble('last_longitude') ?? -122.0841;

            await FirebaseFirestore.instance
                .collection('drivers')
                .doc(user.uid)
                .set({
              'fcmToken': token,
              'isDriverActive': true,
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
            });

            if (kDebugMode) {
              print('Created new driver document with FCM token: $token');
            }
          } else {
            if (kDebugMode) {
              print('Error saving FCM token: $e');
            }
          }
        }
      } else {
        if (kDebugMode) {
          print('Cannot save FCM token: User not logged in');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _saveFcmTokenWithErrorHandling: $e');
      }
    }

    // Setup token refresh listener
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('FCM token refreshed: $newToken');
      }
      _saveFcmTokenWithErrorHandling();
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
    }

    // Check if message contains server URL and update if needed
    if (message.data.containsKey('serverUrl')) {
      ApiService.updateServerUrlFromNotification(message.data);
    }

    // For ambulance requests, show a notification with action buttons
    if (message.data.containsKey('requestId') && message.data['type'] == 'ambulance_request') {
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
        'ambulance_requests',
        'Ambulance Requests',
        channelDescription: 'Notifications for new ambulance requests',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        actions: actions,
      );

      // Use standard iOS notification details
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
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
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('Message opened app: ${message.data}');
    }

    // Update server URL if it's included in the notification
    if (message.data.containsKey('serverUrl')) {
      ApiService.updateServerUrlFromNotification(message.data);
    }

    // Handle navigation based on the notification data
    _handleNotificationNavigation(message.data);
  }

  void _handleInitialMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('App opened from terminated state with message: ${message.data}');
    }

    // Update server URL if it's included in the notification
    if (message.data.containsKey('serverUrl')) {
      ApiService.updateServerUrlFromNotification(message.data);
    }

    // Handle navigation based on the notification data
    _handleNotificationNavigation(message.data);
  }

  Future<void> _showNotification(
      String title, String body, Map<String, dynamic> payload) async {
    try {
      // Log before attempting to show notification
      if (kDebugMode) {
        print("Attempting to show notification: $title");
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'ambulance_requests',
        'Ambulance Requests',
        channelDescription: 'Notifications for new ambulance requests',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
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
      
      final Map<String, dynamic> data = jsonDecode(payload);
      
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
      
      // Get current location
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error getting location: $e');
        }
        return;
      }
      
      // Update the request status in Firestore
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
      await FirebaseFirestore.instance
          .collection('ambulanceRequests')
          .doc(requestId)
          .update({
        'status': 'available', // Reset to available for other drivers
        'rejectedBy': FieldValue.arrayUnion([currentUser.uid]), // Track who rejected
      });
      
      if (kDebugMode) {
        print('Request rejected: $requestId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting request from notification: $e');
      }
    }
  }

  // Navigate to driver wrapper after accepting a request
  void _navigateToDriverWrapper() {
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
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (data.containsKey('requestId') && 
        (data.containsKey('type') && data['type'] == 'ambulance_request' || 
         data.containsKey('navigation') && data['navigation'] == 'ambulance_detail')) {
      
      final String requestId = data['requestId'];
      
      // Fetch complete data for the request
      _fetchRequestDataAndNavigate(requestId);
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
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
    print('Background message data: ${message.data}');
  }

  // Check for server URL in the notification and save it
  if (message.data.containsKey('serverUrl')) {
    final String serverUrl = message.data['serverUrl'];
    if (serverUrl.isNotEmpty) {
      try {
        // We can't directly use ApiService here because it might not be initialized
        // So we'll just use SharedPreferences directly
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_url', serverUrl);
        if (kDebugMode) {
          print('Saved server URL from background message: $serverUrl');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving server URL in background handler: $e');
        }
      }
    }
  }
}