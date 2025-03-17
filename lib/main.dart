// File: lib/main.dart
// A simplified version of main.dart that delegates functionality to other files

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medcave/Initialization_files/error_boundary.dart';
import 'package:medcave/Initialization_files/firebase_message_handler.dart';
import 'package:medcave/Initialization_files/permission_handler_widget.dart';
import 'package:medcave/common/services/notification_service.dart';
import 'package:medcave/config/theme/theme.dart';
import 'package:medcave/Users/UserType/user_wrapper.dart';

// Initialize background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseMessageHandler.handleBackgroundMessage(message);
}

// Main function with proper error handling
Future<void> main() async {
  try {
    // Ensure Flutter is initialized before using platform channels
    WidgetsFlutterBinding.ensureInitialized();

    if (kDebugMode) {
      print('Starting app initialization...');
    }

    // Set the background message handler early
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Show permission screen or main app based on permissions
    runApp(const PermissionHandlerWidget());
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