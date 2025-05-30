// File: lib/common/database/model/User/reminder/reminder_db.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/common/services/medicine_notification_manager.dart';

class ReminderModel {
  TimeOfDay? morningBeforeFood;
  TimeOfDay? morningAfterFood;
  TimeOfDay? noonBeforeFood;
  TimeOfDay? noonAfterFood;
  TimeOfDay? nightBeforeFood;
  TimeOfDay? nightAfterFood;

  ReminderModel({
    this.morningBeforeFood,
    this.morningAfterFood,
    this.noonBeforeFood,
    this.noonAfterFood,
    this.nightBeforeFood,
    this.nightAfterFood,
  });

  // Create a model from Firestore document
  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final reminderData = data['reminder'] as Map<String, dynamic>? ?? {};

    return ReminderModel(
      morningBeforeFood: _timeFromMap(
          reminderData['morningBeforeFood'] as Map<String, dynamic>?),
      morningAfterFood: _timeFromMap(
          reminderData['morningAfterFood'] as Map<String, dynamic>?),
      noonBeforeFood:
          _timeFromMap(reminderData['noonBeforeFood'] as Map<String, dynamic>?),
      noonAfterFood:
          _timeFromMap(reminderData['noonAfterFood'] as Map<String, dynamic>?),
      nightBeforeFood: _timeFromMap(
          reminderData['nightBeforeFood'] as Map<String, dynamic>?),
      nightAfterFood:
          _timeFromMap(reminderData['nightAfterFood'] as Map<String, dynamic>?),
    );
  }

  // Convert TimeOfDay to Map for Firestore
  static Map<String, int>? _timeToMap(TimeOfDay? time) {
    if (time == null) return null;
    return {
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  // Convert Map from Firestore to TimeOfDay
  static TimeOfDay? _timeFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    // Get hour and minute with more robust parsing
    final hour = map['hour'] is int
        ? map['hour'] as int
        : map['hour'] is String
            ? int.tryParse(map['hour'] as String) ?? 0
            : 0;

    final minute = map['minute'] is int
        ? map['minute'] as int
        : map['minute'] is String
            ? int.tryParse(map['minute'] as String) ?? 0
            : 0;

    // Validate that we have valid time values
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      if (kDebugMode) {
        print('Invalid time values: hour=$hour, minute=$minute');
      }
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  // Convert model to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'morningBeforeFood': _timeToMap(morningBeforeFood),
      'morningAfterFood': _timeToMap(morningAfterFood),
      'noonBeforeFood': _timeToMap(noonBeforeFood),
      'noonAfterFood': _timeToMap(noonAfterFood),
      'nightBeforeFood': _timeToMap(nightBeforeFood),
      'nightAfterFood': _timeToMap(nightAfterFood),
    };
  }

  // Update a specific time based on type and meal time
  ReminderModel copyWith({
    required String type,
    required String mealTime,
    required TimeOfDay time,
  }) {
    return ReminderModel(
      morningBeforeFood: type == 'morning' && mealTime == 'beforeFood'
          ? time
          : morningBeforeFood,
      morningAfterFood: type == 'morning' && mealTime == 'afterFood'
          ? time
          : morningAfterFood,
      noonBeforeFood:
          type == 'noon' && mealTime == 'beforeFood' ? time : noonBeforeFood,
      noonAfterFood:
          type == 'noon' && mealTime == 'afterFood' ? time : noonAfterFood,
      nightBeforeFood:
          type == 'night' && mealTime == 'beforeFood' ? time : nightBeforeFood,
      nightAfterFood:
          type == 'night' && mealTime == 'afterFood' ? time : nightAfterFood,
    );
  }
}

// Helper class to interact with Firestore for reminders
class ReminderDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debounce timer
  Timer? _saveDebounceTimer;

  // Get reference to user's document
  DocumentReference getUserDocument(String userId) {
    return _firestore.collection('userdata').doc(userId);
  }

  // Fetch reminder data for a user
  Future<ReminderModel> fetchReminderData(String userId) async {
    try {
      final docSnapshot = await getUserDocument(userId).get();

      if (docSnapshot.exists) {
        return ReminderModel.fromFirestore(
            docSnapshot as DocumentSnapshot<Map<String, dynamic>>);
      } else {
        // Return empty model if document doesn't exist
        return ReminderModel();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching reminder data: $e');
      }
      return ReminderModel();
    }
  }

  // Save reminder settings to Firestore with debouncing
  Future<void> saveReminderData(
      String userId, ReminderModel reminderData) async {
    // Cancel any existing debounce timer
    _saveDebounceTimer?.cancel();

    // Create a new timer
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Save the data
        await getUserDocument(userId).set({
          'reminder': reminderData.toMap(),
        }, SetOptions(merge: true));

        if (kDebugMode) {
          print('Reminder data saved for user $userId');
        }

        // Refresh notifications after changes are saved
        // This is a safe place to refresh as it's debounced
        _triggerNotificationRefresh();
      } catch (e) {
        if (kDebugMode) {
          print('Error saving reminder data: $e');
        }
      }
    });
  }

  // Update a specific reminder time with debouncing
  Future<void> updateReminderTime(
      String userId, String type, String mealTime, TimeOfDay time) async {
    try {
      // First fetch the current data
      final currentData = await fetchReminderData(userId);

      // Create updated data
      final updatedData = currentData.copyWith(
        type: type,
        mealTime: mealTime,
        time: time,
      );

      // Save with the built-in debouncer
      await saveReminderData(userId, updatedData);

      if (kDebugMode) {
        print('Reminder time update queued for $type $mealTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating reminder time: $e');
      }
      throw e;
    }
  }

  // Trigger notification refresh safely through manager
  void _triggerNotificationRefresh() {
    // Slight delay to prevent potential collisions with ongoing operations
    Future.delayed(const Duration(milliseconds: 300), () {
      MedicineNotificationManager().refreshNotifications();
    });
  }

  // Clean up method to cancel subscriptions and timers
  void dispose() {
    _saveDebounceTimer?.cancel();
  }
}
