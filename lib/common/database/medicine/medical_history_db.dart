import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MedicalRecord {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String recordType; // e.g., 'allergy', 'surgery', 'diagnosis', 'vaccination'
  final List<String>? attachments; // URLs to any attached documents
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.recordType,
    this.attachments,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      recordType: map['recordType'] ?? '',
      attachments: map['attachments'] != null ? List<String>.from(map['attachments']) : null,
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'recordType': recordType,
      'attachments': attachments,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class MedicalHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'medicalRecords';

  // Add a new medical record
  Future<String> addMedicalRecord(MedicalRecord record) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc();
      final recordWithId = MedicalRecord(
        id: docRef.id,
        title: record.title,
        description: record.description,
        date: record.date,
        recordType: record.recordType,
        attachments: record.attachments,
        userId: record.userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await docRef.set(recordWithId.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding medical record: $e');
      }
      throw e;
    }
  }

  // Get all medical records for a user
  Stream<List<MedicalRecord>> getMedicalHistory(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MedicalRecord.fromMap(doc.data())).toList();
    });
  }

  // Get medical records by type
  Stream<List<MedicalRecord>> getMedicalRecordsByType(String userId, String recordType) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .where('recordType', isEqualTo: recordType)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MedicalRecord.fromMap(doc.data())).toList();
    });
  }

  // Update a medical record
  Future<void> updateMedicalRecord(MedicalRecord record) async {
    try {
      await _firestore.collection(_collectionPath).doc(record.id).update({
        'title': record.title,
        'description': record.description,
        'date': record.date,
        'recordType': record.recordType,
        'attachments': record.attachments,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating medical record: $e');
      }
      throw e;
    }
  }

  // Delete a medical record
  Future<void> deleteMedicalRecord(String recordId) async {
    try {
      await _firestore.collection(_collectionPath).doc(recordId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting medical record: $e');
      }
      throw e;
    }
  }
}