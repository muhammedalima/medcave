import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Medicine {
  final String id;
  final String name;
  final List<String> schedule; // e.g., ["morning", "noon", "night"]
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.schedule,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      schedule: List<String>.from(map['schedule'] ?? []),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      isActive: map['isActive'] ?? true,
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'schedule': schedule,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'medicines';

  // Add a new medicine
  Future<String> addMedicine(Medicine medicine) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc();
      final medicineWithId = Medicine(
        id: docRef.id,
        name: medicine.name,
        schedule: medicine.schedule,
        startDate: medicine.startDate,
        endDate: medicine.endDate,
        isActive: medicine.isActive,
        userId: medicine.userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await docRef.set(medicineWithId.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding medicine: $e');
      }
      throw e;
    }
  }

  // Get all active medicines for a user
  Stream<List<Medicine>> getActiveMedicines(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Medicine.fromMap(doc.data())).toList();
    });
  }
  
  // Get past medicines for a user
  Stream<List<Medicine>> getPastMedicines(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Medicine.fromMap(doc.data())).toList();
    });
  }

  // Update a medicine
  Future<void> updateMedicine(Medicine medicine) async {
    try {
      await _firestore.collection(_collectionPath).doc(medicine.id).update({
        'name': medicine.name,
        'schedule': medicine.schedule,
        'startDate': medicine.startDate,
        'endDate': medicine.endDate,
        'isActive': medicine.isActive,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating medicine: $e');
      }
      throw e;
    }
  }

  // Set a medicine as inactive (moved to past medicines)
  Future<void> discontinueMedicine(String medicineId) async {
    try {
      await _firestore.collection(_collectionPath).doc(medicineId).update({
        'isActive': false,
        'endDate': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error discontinuing medicine: $e');
      }
      throw e;
    }
  }

  // Delete a medicine (if needed)
  Future<void> deleteMedicine(String medicineId) async {
    try {
      await _firestore.collection(_collectionPath).doc(medicineId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting medicine: $e');
      }
      throw e;
    }
  }
}