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

  // In-memory map to track scheduled notifications by medicine and timing
  // Key is "${medicineName}_${timing}" to identify unique medicine/timing combinations
  static final Map<String, Map<String, dynamic>> _scheduledNotificationsMap =
      {};

  // Initialize the service
  Future<void> initialize() async {
    try {
      // Load pending notifications from storage to in-memory map
      await _loadPendingNotifications();

      // Start the timer that checks for notifications that need to be moved to history
      _startNotificationProcessingTimer();

      if (kDebugMode) {
        print('MedicineNotificationService initialized successfully');
        print(
            'Loaded ${_scheduledNotificationsMap.length} scheduled notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing MedicineNotificationService: $e');
      }
    }
  }

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

      // 2. Get pending notifications from in-memory map
      final List<Map<String, dynamic>> pendingNotifications =
          _scheduledNotificationsMap.values.toList();

      // Mark all pending notifications as pending for the UI
      for (var notification in pendingNotifications) {
        notification['isPending'] = true;
      }

      // 3. Combine both lists
      final List<Map<String, dynamic>> allNotifications = [
        ...historyNotifications.map((n) => Map<String, dynamic>.from(n)),
        ...pendingNotifications
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
      // First check if it's in the scheduled map
      String? keyToRemove;
      for (var entry in _scheduledNotificationsMap.entries) {
        if (entry.value['id'] == id) {
          keyToRemove = entry.key;
          break;
        }
      }

      if (keyToRemove != null) {
        // Remove from scheduled map
        _scheduledNotificationsMap.remove(keyToRemove);

        // Save updated map to storage
        await _savePendingNotifications();

        if (kDebugMode) {
          print('Removed scheduled notification with id $id');
        }
      } else {
        // Try to remove from history
        final prefs = await SharedPreferences.getInstance();
        final String historyJson =
            prefs.getString('notification_history') ?? '[]';

        try {
          List<dynamic> historyNotifications = jsonDecode(historyJson);
          final beforeCount = historyNotifications.length;

          historyNotifications.removeWhere((item) => item['id'] == id);

          if (historyNotifications.length < beforeCount) {
            // Found and removed from history
            await prefs.setString(
                'notification_history', jsonEncode(historyNotifications));

            if (kDebugMode) {
              print('Removed notification with id $id from history');
            }
          } else {
            if (kDebugMode) {
              print('Notification with id $id not found in history');
            }
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

      // Clear history
      await prefs.setString('notification_history', '[]');

      // Clear scheduled notifications map
      _scheduledNotificationsMap.clear();

      // Save empty map to storage
      await _savePendingNotifications();

      // Notify listeners
      _notificationStreamController.add(null);

      if (kDebugMode) {
        print('Cleared all notifications (history and scheduled)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing notifications: $e');
      }
      rethrow;
    }
  }

  // Load pending notifications from shared preferences into the in-memory map
  static Future<void> _loadPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pendingJson = prefs.getString('pending_notifications_map');

      if (pendingJson != null && pendingJson.isNotEmpty) {
        final Map<String, dynamic> parsed = jsonDecode(pendingJson);

        // Clear existing data
        _scheduledNotificationsMap.clear();

        // Convert string keys back to map entries
        parsed.forEach((key, value) {
          _scheduledNotificationsMap[key] = Map<String, dynamic>.from(value);
        });

        if (kDebugMode) {
          print(
              'Loaded ${_scheduledNotificationsMap.length} scheduled notifications');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading pending notifications: $e');
      }
    }
  }

  // Save pending notifications from in-memory map to shared preferences
  static Future<void> _savePendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonMap = jsonEncode(_scheduledNotificationsMap);
      await prefs.setString('pending_notifications_map', jsonMap);

      if (kDebugMode) {
        print(
            'Saved ${_scheduledNotificationsMap.length} scheduled notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving pending notifications: $e');
      }
    }
  }

  // Add or update a pending notification
  static Future<void> addOrUpdatePendingNotification(
      {required String medicineName,
      required String body,
      required String timing,
      required DateTime scheduledTime}) async {
    try {
      // Create a unique key for this medicine+timing combination
      final String uniqueKey = '${medicineName}_$timing';

      // Check if we already have a scheduled notification for this medicine and timing
      final bool isUpdate = _scheduledNotificationsMap.containsKey(uniqueKey);

      // Create a unique ID (reuse existing ID if updating)
      final String id = isUpdate
          ? _scheduledNotificationsMap[uniqueKey]!['id']
          : '${DateTime.now().millisecondsSinceEpoch}_${medicineName.hashCode}';

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
        'isPending': true,
        'updatedAt': DateTime.now().toIso8601String() // Track last update time
      };

      // Store in the map
      _scheduledNotificationsMap[uniqueKey] = notification;

      // Save to persistent storage
      await _savePendingNotifications();

      // Notify listeners
      _notificationStreamController.add(null);

      if (kDebugMode) {
        if (isUpdate) {
          print(
              'Updated scheduled notification for $medicineName ($timing) at ${scheduledTime.toIso8601String()}');
        } else {
          print(
              'Added scheduled notification for $medicineName ($timing) at ${scheduledTime.toIso8601String()}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding/updating scheduled notification: $e');
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
      if (_scheduledNotificationsMap.isEmpty) {
        return;
      }

      final now = DateTime.now();
      final List<Map<String, dynamic>> notificationsToMove = [];
      final List<String> keysToRemove = [];

      // Check each pending notification
      _scheduledNotificationsMap.forEach((key, notification) {
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
              notificationsToMove.add(Map<String, dynamic>.from(notification));

              // Mark for removal from the map
              keysToRemove.add(key);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing notification: $e');
          }
        }
      });

      // Remove processed notifications from the map
      for (final key in keysToRemove) {
        _scheduledNotificationsMap.remove(key);
      }

      // Save updates to the map
      if (keysToRemove.isNotEmpty) {
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
