// File: lib/common/services/medicine_notification_manager.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medcave/common/database/model/medicineNotification/medicine_notify_db.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medcave/common/database/model/User/reminder/reminder_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/common/services/medicine_notification_service.dart';

class MedicineNotificationManager {
  // Singleton pattern
  static final MedicineNotificationManager _instance =
      MedicineNotificationManager._internal();

  // Flag to track initialization status
  bool _isInitialized = false;

  // Flag to prevent nested refresh calls
  bool _isRefreshing = false;

  // Global refresh debounce timer
  Timer? _refreshDebounceTimer;

  // Data refresh debounce period
  static const refreshDebounceMs = 1000;

  factory MedicineNotificationManager() => _instance;

  MedicineNotificationManager._internal() {
    // Initialize timezone data
    try {
      tz_data.initializeTimeZones();
      _localTimeZone = tz.local;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing timezone data: $e');
      }
    }
  }

  // Flutter local notifications plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Local timezone
  late tz.Location _localTimeZone;

  // Scheduled notification IDs
  final Map<String, List<int>> _scheduledNotifications = {};

  // Notification channel ID
  static const String channelId = 'medicine_reminders';
  static const String channelName = 'Medicine Reminders';
  static const String channelDescription =
      'Notifications for medicine reminders';

  // Initialize the notification manager
  Future<void> init() async {
    // Prevent double initialization
    if (_isInitialized) {
      if (kDebugMode) {
        print("MedicineNotificationManager already initialized, skipping...");
      }
      return;
    }

    try {
      if (kDebugMode) {
        print("Initializing medicine notification manager...");
      }

      // Initialize the notifications plugin platform
      await _initializeNotificationsPlatform();

      // Load previously scheduled notifications
      await _loadScheduledNotifications();

      // Mark as initialized
      _isInitialized = true;

      if (kDebugMode) {
        print("Medicine notification manager initialized successfully");
      }

      // Check for medicines that need notifications for the current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await refreshNotifications();
      }

      // Set up auth listener AFTER we're fully initialized
      _setupAuthListener();
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing medicine notification manager: $e");
      }
    }
  }

  // Initialize notification platform settings
  Future<void> _initializeNotificationsPlatform() async {
    try {
      // Android-specific initialization
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS-specific initialization
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin with settings
      await _notificationsPlugin.initialize(initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print("Notification tapped: ${response.payload}");
        }
        // Handle notification tap here - could navigate to medicine screen
      });

      // Create notification channel on Android
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'medicine_reminders',
            'Medicine Reminders',
            description: 'Notifications for medicine reminders',
            importance: Importance.high,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing notifications platform: $e");
      }
    }
  }

  // Setup auth state change listener
  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User signed in, schedule notifications with debounce
        if (kDebugMode) {
          print(
              "User signed in: ${user.uid}, scheduling medicine notifications");
        }
        _debouncedRefresh();
      } else {
        // User signed out, cancel notifications
        if (kDebugMode) {
          print("User signed out, canceling medicine notifications");
        }
        cancelAllNotifications();
      }
    });
  }

  // Load previously scheduled notifications from storage
  Future<void> _loadScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys that start with "medicine_notifications_"
      final allKeys = prefs.getKeys();
      final notificationKeys = allKeys
          .where((key) => key.startsWith('medicine_notifications_'))
          .toList();

      for (final key in notificationKeys) {
        final userId = key.replaceFirst('medicine_notifications_', '');
        final notificationIdsList = prefs.getStringList(key) ?? [];

        final notificationIds = notificationIdsList
            .map((id) => int.tryParse(id))
            .where((id) => id != null)
            .cast<int>()
            .toList();

        if (notificationIds.isNotEmpty) {
          _scheduledNotifications[userId] = notificationIds;
        }
      }

      if (kDebugMode) {
        print(
            "Loaded previously scheduled notifications for ${_scheduledNotifications.length} users");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading scheduled notifications: $e");
      }
    }
  }

  // Save scheduled notifications to storage
  Future<void> _saveScheduledNotifications(
      String userId, List<int> notificationIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save the notification IDs for this user
      await prefs.setStringList(
        'medicine_notifications_$userId',
        notificationIds.map((id) => id.toString()).toList(),
      );

      // Update the in-memory map
      _scheduledNotifications[userId] = notificationIds;

      if (kDebugMode) {
        print(
            "Saved ${notificationIds.length} notification IDs for user $userId");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error saving scheduled notifications: $e");
      }
    }
  }

  // Global debounced refresh method - creates a single entry point for refreshes
  void _debouncedRefresh() {
    // Cancel any existing timer
    _refreshDebounceTimer?.cancel();

    // Create a new timer for the refresh
    _refreshDebounceTimer =
        Timer(const Duration(milliseconds: refreshDebounceMs), () {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        refreshNotifications();
      }
    });
  }

  // Refresh notifications with proper debouncing and recursive call protection
  Future<void> refreshNotifications() async {
    // Early exit if we're already refreshing (prevents recursion)
    if (_isRefreshing) {
      if (kDebugMode) {
        print("Refresh already in progress, skipping");
      }
      return;
    }

    try {
      // Set flag to prevent nested calls
      _isRefreshing = true;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _scheduleUserNotifications(currentUser.uid);

        if (kDebugMode) {
          print("Notifications refreshed for user ${currentUser.uid}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error refreshing notifications: $e");
      }
    } finally {
      // Reset flag when done
      _isRefreshing = false;
    }
  }

  // Schedule notifications for a user directly (internal implementation)
  Future<void> _scheduleUserNotifications(String userId) async {
    try {
      if (kDebugMode) {
        print("Starting notification scheduling for user $userId");
      }

      // Get user's reminder settings - direct Firestore read
      final ReminderModel reminderModel = await _getReminderData(userId);

      // Get active medicines with notifications enabled - direct Firestore read
      final List<MedicineNotificationData> medicines =
          await _getMedicineNotificationData(userId);

      if (kDebugMode) {
        print("Fetched ${medicines.length} medicines for user $userId");
      }

      // Filter active medicines
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final activeMedicines = medicines
          .where((med) => med.isActiveOn(today) && med.shouldNotify())
          .toList();

      if (activeMedicines.isEmpty) {
        if (kDebugMode) {
          print(
              "No active medicines with notifications, canceling existing notifications");
        }
        await cancelUserNotifications(userId);
        return;
      }

      // Cancel existing notifications
      await cancelUserNotifications(userId);

      // Schedule notifications for each medicine
      int notificationId = 1;
      final List<int> medicineNotificationIds = [];

      for (final medicine in activeMedicines) {
        if (kDebugMode) {
          print("Scheduling notifications for medicine: ${medicine.name}");
        }

        bool matchesSchedule = false;

        if (medicine.morning) {
          final TimeOfDay? reminderTime = medicine.beforeMeals
              ? reminderModel.morningBeforeFood
              : reminderModel.morningAfterFood;

          if (reminderTime != null) {
            if (kDebugMode) {
              print(
                  "Scheduling morning notification at ${reminderTime.hour}:${reminderTime.minute}");
            }

            final id = await _scheduleDaily(
              notificationId++,
              medicine.name,
              'Time to take your morning dose',
              reminderTime,
              medicine.beforeMeals ? 'before breakfast' : 'after breakfast',
            );
            if (id != null) {
              medicineNotificationIds.add(id);
              matchesSchedule = true;
            }
          }
        }

        if (medicine.afternoon) {
          final TimeOfDay? reminderTime = medicine.beforeMeals
              ? reminderModel.noonBeforeFood
              : reminderModel.noonAfterFood;

          if (reminderTime != null) {
            if (kDebugMode) {
              print(
                  "Scheduling afternoon notification at ${reminderTime.hour}:${reminderTime.minute}");
            }

            final id = await _scheduleDaily(
              notificationId++,
              medicine.name,
              'Time to take your afternoon dose',
              reminderTime,
              medicine.beforeMeals ? 'before lunch' : 'after lunch',
            );
            if (id != null) {
              medicineNotificationIds.add(id);
              matchesSchedule = true;
            }
          }
        }

        if (medicine.evening) {
          final TimeOfDay? reminderTime = medicine.beforeMeals
              ? reminderModel.nightBeforeFood
              : reminderModel.nightAfterFood;

          if (reminderTime != null) {
            if (kDebugMode) {
              print(
                  "Scheduling evening notification at ${reminderTime.hour}:${reminderTime.minute}");
            }

            final id = await _scheduleDaily(
              notificationId++,
              medicine.name,
              'Time to take your evening dose',
              reminderTime,
              medicine.beforeMeals ? 'before dinner' : 'after dinner',
            );
            if (id != null) {
              medicineNotificationIds.add(id);
              matchesSchedule = true;
            }
          }
        }

        if (!matchesSchedule && kDebugMode) {
          if (kDebugMode) {
            print(
                "Warning: Medicine ${medicine.name} has notifications enabled but no matching reminder times");
          }
        }
      }

      // Save scheduled notification IDs
      if (medicineNotificationIds.isNotEmpty) {
        await _saveScheduledNotifications(userId, medicineNotificationIds);

        if (kDebugMode) {
          print(
              'Successfully scheduled ${medicineNotificationIds.length} notifications for user $userId');
        }
      } else {
        if (kDebugMode) {
          print('No notifications were scheduled for user $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notifications: $e');
      }
    }
  }

  // Public method for explicit notification scheduling (used from main.dart)
  Future<void> scheduleNotifications(String userId) async {
    // Use the same debouncing mechanism for consistency
    _debouncedRefresh();
  }

  // Get reminder data directly from Firestore
  Future<ReminderModel> _getReminderData(String userId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('userdata')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        return ReminderModel.fromFirestore(
            docSnapshot as DocumentSnapshot<Map<String, dynamic>>);
      } else {
        return ReminderModel();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching reminder data: $e');
      }
      return ReminderModel();
    }
  }

  // Get medicine notification data directly from Firestore
  Future<List<MedicineNotificationData>> _getMedicineNotificationData(
      String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('userdata')
          .doc(userId)
          .collection('medicines')
          .get();

      if (kDebugMode) {
        print(
            'Retrieved ${snapshot.docs.length} medicine documents for user $userId');
      }

      final List<MedicineNotificationData> medicines = [];

      for (var doc in snapshot.docs) {
        try {
          // Use custom model to handle the conversion
          final medicineData =
              MedicineNotificationData.fromFirestore(doc.data());
          medicines.add(medicineData);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing medicine document: $e');
          }
          // Continue with the next document
        }
      }

      return medicines;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting medicine notification data: $e');
      }
      return [];
    }
  }

  // Schedule a daily notification with pending notification support
  Future<int?> _scheduleDaily(
    int id,
    String title,
    String body,
    TimeOfDay time,
    String payload,
  ) async {
    try {
      // Create notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription: 'Reminders for taking medicines',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Calculate the time for the notification
      final now = DateTime.now();
      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If the time has already passed for today, schedule for tomorrow
      final tz.TZDateTime scheduledTZDate;
      if (scheduledDate.isBefore(now)) {
        scheduledTZDate = tz.TZDateTime.from(
            scheduledDate.add(const Duration(days: 1)), _localTimeZone);
      } else {
        scheduledTZDate = tz.TZDateTime.from(scheduledDate, _localTimeZone);
      }

      // Schedule the notification
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      // IMPORTANT CHANGE: Add to pending notifications in MedicineNotificationService
      // This will show up immediately in the UI but will move to history when scheduled time is reached
      await _addMedicineToPendingNotifications(
          title, body, payload, scheduledTZDate.toLocal());

      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling daily notification: $e');
      }
      return null;
    }
  }

  // Add medicine reminder to pending notifications via MedicineNotificationService
  Future<void> _addMedicineToPendingNotifications(String medicineName,
      String body, String timing, DateTime scheduledTime) async {
    try {
      // Extract just the medicine name without "Time to take" etc.
      String cleanMedicineName = medicineName;

      // Add to pending notifications through the MedicineNotificationService
      await MedicineNotificationService.addPendingNotification(
          medicineName: cleanMedicineName,
          body: body,
          timing: timing,
          scheduledTime: scheduledTime);

      if (kDebugMode) {
        print(
            'Added pending notification for $cleanMedicineName at $scheduledTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding medicine to pending notifications: $e');
      }
    }
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      _scheduledNotifications.clear();

      // Clear saved notification IDs
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final notificationKeys = allKeys
          .where((key) => key.startsWith('medicine_notifications_'))
          .toList();

      for (final key in notificationKeys) {
        await prefs.remove(key);
      }

      // Also clear all pending notifications from MedicineNotificationService
      try {
        await MedicineNotificationService.clearNotificationHistory();
      } catch (e) {
        if (kDebugMode) {
          print(
              'Error clearing notifications from MedicineNotificationService: $e');
        }
      }

      if (kDebugMode) {
        print("Cancelled all medicine notifications");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling notifications: $e');
      }
    }
  }

  // Cancel notifications for a specific user
  Future<void> cancelUserNotifications(String userId) async {
    try {
      final notificationIds = _scheduledNotifications[userId] ?? [];
      for (final id in notificationIds) {
        await _notificationsPlugin.cancel(id);
      }

      _scheduledNotifications.remove(userId);

      // Remove saved notification IDs
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('medicine_notifications_$userId');

      // Also clear pending notifications from MedicineNotificationService
      // We're not removing this because it would affect all users
      // If user-specific cancellation is needed, modify MedicineNotificationService to support it

      if (kDebugMode) {
        print(
            "Cancelled ${notificationIds.length} notifications for user $userId");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling user notifications: $e');
      }
    }
  }

  // Clean up resources
  void dispose() {
    _refreshDebounceTimer?.cancel();
  }
}
