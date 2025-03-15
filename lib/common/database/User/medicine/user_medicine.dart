// lib/common/models/medicine.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String userId;
  final String name;
  final List<String> schedule;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String dosage;
  final String notes;

  Medicine({
    required this.id,
    required this.userId,
    required this.name,
    required this.schedule,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.dosage = '',
    this.notes = '',
  });

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      schedule: List<String>.from(map['schedule'] ?? []),
      startDate: (map['startDate'] is Timestamp) 
          ? (map['startDate'] as Timestamp).toDate() 
          : DateTime.now(),
      endDate: map['endDate'] != null 
          ? (map['endDate'] is Timestamp ? (map['endDate'] as Timestamp).toDate() : null) 
          : null,
      isActive: map['isActive'] ?? true,
      dosage: map['dosage'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'schedule': schedule,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'dosage': dosage,
      'notes': notes,
    };
  }
}