import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  factory ReminderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final reminderData = data['reminder'] ?? {};
    
    return ReminderModel(
      morningBeforeFood: _timeFromMap(reminderData['morningBeforeFood']),
      morningAfterFood: _timeFromMap(reminderData['morningAfterFood']),
      noonBeforeFood: _timeFromMap(reminderData['noonBeforeFood']),
      noonAfterFood: _timeFromMap(reminderData['noonAfterFood']),
      nightBeforeFood: _timeFromMap(reminderData['nightBeforeFood']),
      nightAfterFood: _timeFromMap(reminderData['nightAfterFood']),
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
    return TimeOfDay(
      hour: map['hour'] ?? 0,
      minute: map['minute'] ?? 0,
    );
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
          ? time : morningBeforeFood,
      morningAfterFood: type == 'morning' && mealTime == 'afterFood' 
          ? time : morningAfterFood,
      noonBeforeFood: type == 'noon' && mealTime == 'beforeFood' 
          ? time : noonBeforeFood,
      noonAfterFood: type == 'noon' && mealTime == 'afterFood' 
          ? time : noonAfterFood,
      nightBeforeFood: type == 'night' && mealTime == 'beforeFood' 
          ? time : nightBeforeFood,
      nightAfterFood: type == 'night' && mealTime == 'afterFood' 
          ? time : nightAfterFood,
    );
  }
}

// Helper class to interact with Firestore for reminders
class ReminderDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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
          docSnapshot as DocumentSnapshot<Map<String, dynamic>>
        );
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
  
  // Save reminder settings to Firestore
  Future<void> saveReminderData(String userId, ReminderModel reminderData) async {
    try {
      await getUserDocument(userId).set({
        'reminder': reminderData.toMap(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving reminder data: $e');
      }
      throw e;
    }
  }
  
  // Update a specific reminder time
  Future<void> updateReminderTime(
    String userId, 
    String type,
    String mealTime,
    TimeOfDay time
  ) async {
    try {
      // First fetch the current data
      final currentData = await fetchReminderData(userId);
      
      // Create updated data
      final updatedData = currentData.copyWith(
        type: type,
        mealTime: mealTime,
        time: time,
      );
      
      // Save updated data
      await saveReminderData(userId, updatedData);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating reminder time: $e');
      }
      throw e;
    }
  }
}