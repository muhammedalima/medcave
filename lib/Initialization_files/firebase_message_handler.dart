import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:medcave/firebase_options.dart';

/// Handles Firebase Cloud Messaging messages
class FirebaseMessageHandler {
  /// Handle background messages from Firebase Cloud Messaging
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
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
      
      // Add custom handling logic here
      // This could include saving the notification to SharedPreferences
      // or updating a local database
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error handling background message: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }
  
  /// Handle a message received when the app is in the foreground
  static Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('Handling a foreground message: ${message.messageId}');
        print('Message data: ${message.data}');
        print('Message notification: ${message.notification?.title}');
      }
      
      // Add custom handling logic here
    } catch (e) {
      if (kDebugMode) {
        print('Error handling foreground message: $e');
      }
    }
  }
  
  /// Handle a message when the user taps on the notification
  static Future<void> handleMessageOpenedApp(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('Message opened app: ${message.messageId}');
        print('Message data: ${message.data}');
        print('Message notification: ${message.notification?.title}');
      }
      
      // Add navigation or other UI-related logic here
    } catch (e) {
      if (kDebugMode) {
        print('Error handling message that opened app: $e');
      }
    }
  }
}