import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool morning;
  final bool afternoon;
  final bool evening;
  final bool beforeMeals; // New field for taking medicine before meals
  final bool afterMeals;  // New field for taking medicine after meals
  final bool notify;

  Medicine({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.morning = false,
    this.afternoon = false,
    this.evening = false,
    this.beforeMeals = false, // Default to false
    this.afterMeals = false,  // Default to false
    this.notify = true,
  });

  // Convert the Medicine object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'morning': morning,
      'afternoon': afternoon,
      'evening': evening,
      'beforeMeals': beforeMeals, // Add to map
      'afterMeals': afterMeals,   // Add to map
      'notify': notify,
    };
  }

  // Create a Medicine object from a Map
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      name: map['name'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      morning: map['morning'] ?? false,
      afternoon: map['afternoon'] ?? false,
      evening: map['evening'] ?? false,
      beforeMeals: map['beforeMeals'] ?? false, // Parse from map
      afterMeals: map['afterMeals'] ?? false,   // Parse from map
      notify: map['notify'] ?? true,
    );
  }

  // Get a list of schedule times as strings (e.g., ["morning", "evening"])
  List<String> get schedule {
    List<String> scheduleList = [];
    if (morning) scheduleList.add("Morning");
    if (afternoon) scheduleList.add("Afternoon");
    if (evening) scheduleList.add("Evening");
    return scheduleList;
  }
  
  // Get food timing as string (e.g., "Before Meals" or "After Meals")
  String get foodTiming {
    if (beforeMeals) {
      return "Before Meals";
    } else {
      return "After Meals";
    }
  }

  // Create a copy of this Medicine with given fields replaced with new values
  Medicine copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? morning,
    bool? afternoon,
    bool? evening,
    bool? beforeMeals,
    bool? afterMeals,
    bool? notify,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      morning: morning ?? this.morning,
      afternoon: afternoon ?? this.afternoon,
      evening: evening ?? this.evening,
      beforeMeals: beforeMeals ?? this.beforeMeals,
      afterMeals: afterMeals ?? this.afterMeals,
      notify: notify ?? this.notify,
    );
  }
}