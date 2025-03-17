// File: lib/common/services/medicine_notification_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing medicine notifications, history, and pending notifications
class MedicineNotificationService {
  // Navigation key for context access
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Stream controller for notification events
  static final StreamController<void> _notificationStreamController =
      StreamController<void>.broadcast();

  // Stream getter for notification events
  static Stream<void> get notificationStream =>
      _notificationStreamController.stream;

  // Initialize the service
  Future<void> initialize() async {
    try {
      // Load pending notifications and start the processing timer
      await _loadPendingNotifications();
      _startNotificationProcessingTimer();

      if (kDebugMode) {
        print('MedicineNotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing MedicineNotificationService: $e');
      }
    }
  }

  // List to store pending notifications
  static final List<Map<String, dynamic>> _pendingNotifications = [];

  // Get combined notification history from both active and pending
  static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Get regular notification history
      final String notificationsJson =
          prefs.getString('notification_history') ?? '[]';
      List<dynamic> historyNotifications = [];

      try {
        historyNotifications = jsonDecode(notificationsJson);
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding notification history: $e');
        }
        historyNotifications = [];
      }

      // 2. Get pending notifications
      final String pendingJson =
          prefs.getString('pending_notifications') ?? '[]';
      List<dynamic> pendingNotifications = [];

      try {
        pendingNotifications = jsonDecode(pendingJson);

        // Convert scheduled time to display time for UI
        for (var notification in pendingNotifications) {
          // Mark as pending in the UI
          notification['isPending'] = true;

          // Use scheduledTime as the time field for sorting
          if (notification['scheduledTime'] != null) {
            notification['time'] = notification['scheduledTime'];
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding pending notifications: $e');
        }
        pendingNotifications = [];
      }

      // 3. Combine both lists
      final List<Map<String, dynamic>> allNotifications = [
        ...historyNotifications.map((n) => Map<String, dynamic>.from(n)),
        ...pendingNotifications.map((n) => Map<String, dynamic>.from(n))
      ];

      // 4. Parse the ISO date strings back to DateTime for proper sorting
      for (var notification in allNotifications) {
        try {
          final String timeStr =
              notification['time'] ?? DateTime.now().toIso8601String();
          notification['time'] = DateTime.parse(timeStr);
        } catch (e) {
          notification['time'] = DateTime.now(); // Default if parsing fails
        }
      }

      // 5. Sort by time (newest first)
      allNotifications.sort(
          (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

      return allNotifications;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting combined notification history: $e');
      }
      return [];
    }
  }

  // Delete a notification from history or pending
  static Future<void> deleteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Check pending notifications first
      String pendingJson = prefs.getString('pending_notifications') ?? '[]';
      List<dynamic> pendingNotifications = [];
      bool removedFromPending = false;

      try {
        pendingNotifications = jsonDecode(pendingJson);
        final beforeLength = pendingNotifications.length;
        pendingNotifications.removeWhere((item) => item['id'] == id);

        if (pendingNotifications.length < beforeLength) {
          // Found and removed from pending
          removedFromPending = true;
          await prefs.setString(
              'pending_notifications', jsonEncode(pendingNotifications));
          if (kDebugMode) {
            print('Removed notification $id from pending list');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing pending notifications: $e');
        }
      }

      // 2. If not found in pending, check history
      if (!removedFromPending) {
        String historyJson = prefs.getString('notification_history') ?? '[]';
        List<dynamic> historyNotifications = [];

        try {
          historyNotifications = jsonDecode(historyJson);
          historyNotifications.removeWhere((item) => item['id'] == id);
          await prefs.setString(
              'notification_history', jsonEncode(historyNotifications));
          if (kDebugMode) {
            print('Removed notification $id from history');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing history notifications: $e');
          }
        }
      }

      // Notify listeners
      _notificationStreamController.add(null);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
      rethrow;
    }
  }

  // Clear all notifications (both history and pending)
  static Future<void> clearNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear both notification lists
      await prefs.setString('notification_history', '[]');
      await prefs.setString('pending_notifications', '[]');

      // Notify listeners
      _notificationStreamController.add(null);

      if (kDebugMode) {
        print('Cleared all notifications (history and pending)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing notifications: $e');
      }
      rethrow;
    }
  }

  // Methods for managing pending notifications

  // Load pending notifications from shared preferences
  static Future<void> _loadPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pendingJson = prefs.getString('pending_notifications');
      if (pendingJson != null && pendingJson.isNotEmpty) {
        final List<dynamic> parsed = jsonDecode(pendingJson);
        _pendingNotifications.clear();
        for (var item in parsed) {
          _pendingNotifications.add(Map<String, dynamic>.from(item));
        }
        if (kDebugMode) {
          print('Loaded ${_pendingNotifications.length} pending notifications');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading pending notifications: $e');
      }
    }
  }

  // Save pending notifications to shared preferences
  static Future<void> _savePendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'pending_notifications', jsonEncode(_pendingNotifications));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving pending notifications: $e');
      }
    }
  }

  // Add a new pending notification
  static Future<void> addPendingNotification(
      {required String medicineName,
      required String body,
      required String timing,
      required DateTime scheduledTime}) async {
    try {
      // Create a unique ID
      final String id =
          '${DateTime.now().millisecondsSinceEpoch}_${medicineName.hashCode}';

      // Create notification record
      final Map<String, dynamic> notification = {
        'id': id,
        'title': 'Medicine Reminder: $medicineName',
        'body': body,
        'scheduledTime': scheduledTime.toIso8601String(),
        'time': scheduledTime.toIso8601String(), // For sorting in UI
        'data': {
          'type': 'medication',
          'medicineName': medicineName,
          'timing': timing,
          'scheduled': true
        },
        'type': 'medication',
        'status': 'pending',
        'isPending': true
      };

      // Add to pending list
      _pendingNotifications.add(notification);

      // Save to persistent storage
      await _savePendingNotifications();

      // Notify listeners
      _notificationStreamController.add(null);

      if (kDebugMode) {
        print(
            'Added pending notification for $medicineName at ${scheduledTime.toIso8601String()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding pending notification: $e');
      }
    }
  }

  // Start a timer to process pending notifications
  static void _startNotificationProcessingTimer() {
    // Check every minute
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _processPendingNotifications();
    });

    if (kDebugMode) {
      print('Started notification processing timer');
    }
  }

  // Process pending notifications and move ready ones to history
  static Future<void> _processPendingNotifications() async {
    try {
      if (_pendingNotifications.isEmpty) {
        return;
      }

      final now = DateTime.now();
      final List<Map<String, dynamic>> notificationsToMove = [];
      final List<Map<String, dynamic>> remainingNotifications = [];

      // Check each pending notification
      for (var notification in _pendingNotifications) {
        try {
          final scheduledTimeStr = notification['scheduledTime'];
          if (scheduledTimeStr != null) {
            final scheduledTime = DateTime.parse(scheduledTimeStr);

            // If the scheduled time is now or in the past, move to history
            if (scheduledTime.isBefore(now) ||
                (scheduledTime.year == now.year &&
                    scheduledTime.month == now.month &&
                    scheduledTime.day == now.day &&
                    scheduledTime.hour == now.hour &&
                    scheduledTime.minute == now.minute)) {
              // Update the record for history
              notification['time'] = now.toIso8601String();
              notification['status'] = 'delivered';
              notification.remove('isPending');
              notificationsToMove.add(notification);
            } else {
              // Keep in pending list
              remainingNotifications.add(notification);
            }
          } else {
            // Malformed notification, just keep it
            remainingNotifications.add(notification);
          }
        } catch (e) {
          // Error processing this notification, keep it in list
          remainingNotifications.add(notification);
          if (kDebugMode) {
            print('Error processing notification: $e');
          }
        }
      }

      // Update pending list
      if (_pendingNotifications.length != remainingNotifications.length) {
        _pendingNotifications.clear();
        _pendingNotifications.addAll(remainingNotifications);
        await _savePendingNotifications();
      }

      // Move notifications to history
      if (notificationsToMove.isNotEmpty) {
        await _moveNotificationsToHistory(notificationsToMove);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing pending notifications: $e');
      }
    }
  }

  // Move notifications from pending to history
  static Future<void> _moveNotificationsToHistory(
      List<Map<String, dynamic>> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current stored notifications
      final String notificationsJson =
          prefs.getString('notification_history') ?? '[]';
      List<dynamic> historyNotifications = [];

      try {
        historyNotifications = jsonDecode(notificationsJson);
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding notification history: $e');
        }
        historyNotifications = [];
      }

      // Add all notifications to the beginning of the history list
      for (var notification in notifications) {
        historyNotifications.insert(0, notification);
        if (kDebugMode) {
          print('Moved to history: ${notification['title']}');
        }
      }

      // Limit history to 100 notifications
      if (historyNotifications.length > 100) {
        historyNotifications = historyNotifications.sublist(0, 100);
      }

      // Store back in SharedPreferences
      await prefs.setString(
          'notification_history', jsonEncode(historyNotifications));

      // Notify listeners that notifications have been updated
      _notificationStreamController.add(null);

      if (kDebugMode) {
        print('Moved ${notifications.length} notifications to history');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error moving notifications to history: $e');
      }
    }
  }

  // Add a notification directly to history (for non-medicine notifications)
  static Future<void> addNotificationToHistory({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current stored notifications
      final String notificationsJson =
          prefs.getString('notification_history') ?? '[]';
      List<dynamic> historyNotifications = [];

      try {
        historyNotifications = jsonDecode(notificationsJson);
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding notification history: $e');
        }
        historyNotifications = [];
      }

      // Create new notification
      final now = DateTime.now();
      final Map<String, dynamic> notification = {
        'id': now.millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'time': now.toIso8601String(),
        'data': data ?? {'type': type},
        'type': type,
        'status': 'delivered'
      };

      // Add to beginning of list
      historyNotifications.insert(0, notification);

      // Limit history to 100 notifications
      if (historyNotifications.length > 100) {
        historyNotifications = historyNotifications.sublist(0, 100);
      }

      // Save to storage
      await prefs.setString(
          'notification_history', jsonEncode(historyNotifications));

      // Notify listeners
      _notificationStreamController.add(null);

      if (kDebugMode) {
        print('Added notification to history: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding notification to history: $e');
      }
    }
  }

  // Dispose the service
  static void dispose() {
    _notificationStreamController.close();
  }
}
