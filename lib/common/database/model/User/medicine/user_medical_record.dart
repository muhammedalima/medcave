import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecord {
  final String id;
  final String heading;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;

  MedicalRecord({
    required this.id,
    required this.heading,
    required this.description,
    required this.date,
    required this.userId,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert MedicalRecord object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'heading': heading,
      'description': description,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create a MedicalRecord object from a Firestore document
  factory MedicalRecord.fromMap(Map<String, dynamic> map, String docId) {
    return MedicalRecord(
      id: map['id'] ?? docId,
      heading: map['heading'] ?? 'Medical Record',
      description: map['description'] ?? '',
      date: map['date'] != null 
          ? (map['date'] as Timestamp).toDate() 
          : DateTime.now(),
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Create a copy of this MedicalRecord with given fields replaced with new values
  MedicalRecord copyWith({
    String? id,
    String? heading,
    String? description,
    DateTime? date,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      heading: heading ?? this.heading,
      description: description ?? this.description,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to format date for display
  String getFormattedDate(String format) {
    return format.isEmpty 
        ? '${date.day}- ${_getMonthName(date.month)} -${date.year}'
        : format;
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}