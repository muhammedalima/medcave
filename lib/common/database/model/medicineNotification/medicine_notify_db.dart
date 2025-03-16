// File: lib/common/database/model/medicineNotification/medicine_notify_db.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MedicineNotificationData {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool morning;
  final bool afternoon;
  final bool evening;
  final bool beforeMeals;
  final bool notify;

  MedicineNotificationData({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.morning = false,
    this.afternoon = false,
    this.evening = false,
    this.beforeMeals = false,
    this.notify = true,
  });

  /// Create a notification data model from Firestore document data
  factory MedicineNotificationData.fromFirestore(Map<String, dynamic> data) {
    try {
      return MedicineNotificationData(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? 'Medicine',
        startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
        morning: data['morning'] as bool? ?? false,
        afternoon: data['afternoon'] as bool? ?? false,
        evening: data['evening'] as bool? ?? false,
        beforeMeals: data['beforeMeals'] as bool? ?? false,
        notify: data['notify'] as bool? ?? true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating MedicineNotificationData: $e');
      }
      // Return a default medicine with current dates if parsing fails
      return MedicineNotificationData(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? 'Medicine (Error)',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );
    }
  }
  
  /// Check if this medicine is active on a given date
  bool isActiveOn(DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);
    final medStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final medEndDate = DateTime(endDate.year, endDate.month, endDate.day);
    
    return (medStartDate.isBefore(checkDate) || medStartDate.isAtSameMomentAs(checkDate)) &&
           (medEndDate.isAfter(checkDate) || medEndDate.isAtSameMomentAs(checkDate));
  }
  
  /// Check if this medicine should be notified
  bool shouldNotify() {
    return notify && (morning || afternoon || evening);
  }
  
  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'morning': morning,
      'afternoon': afternoon,
      'evening': evening,
      'beforeMeals': beforeMeals,
      'notify': notify,
    };
  }
  
  @override
  String toString() {
    return 'MedicineNotificationData(id: $id, name: $name, notify: $notify, morning: $morning, afternoon: $afternoon, evening: $evening)';
  }
}