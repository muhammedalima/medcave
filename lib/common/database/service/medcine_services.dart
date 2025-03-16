// File: lib/common/database/service/medicine_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:medcave/common/database/model/User/medicine/user_medicine_db.dart';
import 'package:medcave/common/services/medicine_notification_manager.dart';
import 'package:uuid/uuid.dart';

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();
  
  // Debounce timer for database operations
  Timer? _operationDebounceTimer;
  static const operationDebounceMs = 500;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get reference to the medicines collection for the current user
  CollectionReference<Map<String, dynamic>> get medicinesCollection {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }
    return _firestore
        .collection('userdata')
        .doc(currentUserId)
        .collection('medicines');
  }

  // Initialize the service 
  Future<void> initialize() async {
    // No listeners set up here - Firebase will automatically notify Firestore 
    // about changes, and our refresh will be triggered by the main.dart listener
    if (kDebugMode) {
      print("MedicineService initialized");
    }
  }

  // Add a new medicine with debounced notification update
  Future<String> addMedicine(Medicine medicine) async {
    try {
      final String medicineId = _uuid.v4();
      final medicineWithId = medicine.copyWith(id: medicineId);
      
      await medicinesCollection.doc(medicineId).set(medicineWithId.toMap());
      
      // Trigger notification refresh with debounce
      _triggerNotificationRefresh();
      
      return medicineId;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding medicine: $e');
      }
      throw Exception('Failed to add medicine: $e');
    }
  }

  // Add multiple medicines at once with debounced notification update
  Future<List<String>> addMedicines(List<Medicine> medicines) async {
    List<String> medicineIds = [];

    try {
      final batch = _firestore.batch();
      
      for (var medicine in medicines) {
        final String medicineId = _uuid.v4();
        final medicineWithId = medicine.copyWith(id: medicineId);
        
        batch.set(
          medicinesCollection.doc(medicineId),
          medicineWithId.toMap()
        );
        
        medicineIds.add(medicineId);
      }
      
      await batch.commit();
      
      // Trigger notification refresh with debounce
      _triggerNotificationRefresh();
      
      return medicineIds;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding medicines: $e');
      }
      throw Exception('Failed to add medicines: $e');
    }
  }

  // Update a medicine with debounced notification update
  Future<void> updateMedicine(Medicine medicine) async {
    try {
      await medicinesCollection.doc(medicine.id).update(medicine.toMap());
      
      // Trigger notification refresh with debounce
      _triggerNotificationRefresh();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating medicine: $e');
      }
      throw Exception('Failed to update medicine: $e');
    }
  }

  // Delete a medicine with debounced notification update
  Future<void> deleteMedicine(String medicineId) async {
    try {
      await medicinesCollection.doc(medicineId).delete();
      
      // Trigger notification refresh with debounce
      _triggerNotificationRefresh();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting medicine: $e');
      }
      throw Exception('Failed to delete medicine: $e');
    }
  }

  // Update notification setting for a medicine with debounced notification update
  Future<void> updateMedicineNotification(String medicineId, bool notify) async {
    try {
      await medicinesCollection.doc(medicineId).update({'notify': notify});
      
      // Trigger notification refresh with debounce
      _triggerNotificationRefresh();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating medicine notification: $e');
      }
      throw Exception('Failed to update medicine notification: $e');
    }
  }

  // Debounced notification refresh to prevent multiple rapid updates
  void _triggerNotificationRefresh() {
    // Cancel any existing timer
    _operationDebounceTimer?.cancel();
    
    // Create a new timer for the refresh
    _operationDebounceTimer = Timer(Duration(milliseconds: operationDebounceMs), () {
      // Call the notification manager to refresh
      MedicineNotificationManager().refreshNotifications();
    });
  }

  // Get all medicines for the current user
  Stream<List<Medicine>> getMedicines() {
    return medicinesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Medicine.fromMap(doc.data()))
          .toList();
    });
  }

  // Get active medicines (where end date is in the future)
  Stream<List<Medicine>> getActiveMedicines() {
    final DateTime now = DateTime.now();
    
    return medicinesCollection
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Medicine.fromMap(doc.data()))
              .toList();
        });
  }

  // Get all medicines as a List (not Stream) - useful for one-time loading
  Future<List<Medicine>> getMedicinesAsList() async {
    try {
      if (currentUserId == null) {
        return [];
      }
      
      final snapshot = await medicinesCollection.get();
      return snapshot.docs
          .map((doc) => Medicine.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting medicines as list: $e');
      }
      return [];
    }
  }
  
  // Get medicines for a specific user
  Future<List<Medicine>> getMedicinesForUser(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('userdata')
          .doc(userId)
          .collection('medicines')
          .get();
      
      if (kDebugMode) {
        print('Retrieved ${snapshot.docs.length} medicines for user $userId');
      }
      
      return snapshot.docs
          .map((doc) => Medicine.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting medicines for user: $e');
      }
      return [];
    }
  }
  
  // Get past medicines (where end date is in the past)
  Future<List<Medicine>> getPastMedicines() async {
    try {
      final DateTime today = DateTime.now();
      final DateTime todayStart = DateTime(today.year, today.month, today.day);
      final Timestamp todayTimestamp = Timestamp.fromDate(todayStart);
      
      final snapshot = await medicinesCollection
          .where('endDate', isLessThan: todayTimestamp)
          .get();
      
      return snapshot.docs
          .map((doc) => Medicine.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting past medicines: $e');
      }
      return [];
    }
  }
  
  // Check if medicine exists by name and date range
  Future<bool> doesMedicineExist(String name, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await medicinesCollection
          .where('name', isEqualTo: name)
          .where('startDate', isEqualTo: Timestamp.fromDate(startDate))
          .where('endDate', isEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if medicine exists: $e');
      }
      return false;
    }
  }
  
  // Clean up resources
  void dispose() {
    _operationDebounceTimer?.cancel();
  }
}