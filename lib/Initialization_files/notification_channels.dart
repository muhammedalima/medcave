// File: lib/common/initialization/notification_channels.dart
// Defines notification channels for the app

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Centralized definition of notification channels
class NotificationChannels {
  /// Ambulance notification channel for emergency requests
  static const AndroidNotificationChannel ambulanceChannel = AndroidNotificationChannel(
    'ambulance_requests',
    'Ambulance Requests',
    description: 'This channel is used for ambulance request notifications',
    importance: Importance.high,
    playSound: true,
  );

  /// Medicine notification channel for medication reminders
  static const AndroidNotificationChannel medicineChannel = AndroidNotificationChannel(
    'medicine_reminders',
    'Medicine Reminders',
    description: 'This channel is used for medicine reminder notifications',
    importance: Importance.high,
    playSound: true,
  );
}