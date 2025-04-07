import 'package:flutter/foundation.dart';
import 'package:medcave/common/database/model/alternatemedicine/alternate_medicine_db.dart';

class AlternateMedicineFinder {
  AlternateMedicineFinder();

  /// Find alternative medicines based on a medicine name
  ///
  /// [medicineName] The name of the medicine to find alternatives for
  /// Returns a Map with medicine information and a list of alternatives
  Future<Map<String, dynamic>> findAlternativesByName(
      String medicineName) async {
    try {
      if (medicineName.trim().isEmpty) {
        throw MedicineFinderException('Medicine name cannot be empty');
      }

      // Find the generic information for this medicine
      final genericInfo = _findGenericInfoForMedicine(medicineName);

      if (genericInfo != null) {
        // Add the original medicine name to the response
        genericInfo['originalMedicine'] = medicineName;
        
        // Filter out the original medicine from alternatives
        _filterOutOriginalMedicine(genericInfo, medicineName);
        
        return genericInfo;
      }

      return _getDefaultResponse(medicineName: medicineName);
    } catch (e) {
      if (e is MedicineFinderException) rethrow;
      if (kDebugMode) {
        print('Error finding alternative medicines: $e');
      }
      return _getDefaultResponse(medicineName: medicineName);
    }
  }

  /// Find generic information for a medicine name by searching through all alternatives
  Map<String, dynamic>? _findGenericInfoForMedicine(String medicineName) {
    final lowercaseName = medicineName.toLowerCase();

    // Search through all generic medicines
    for (final entry in MedicineData.genericMedicines.entries) {
      final genericName = entry.key;
      final medicineData = entry.value;

      // Check if this medicine is in the alternatives list
      final List<Map<String, dynamic>> alternatives =
          medicineData['alternatives'];

      // Search through alternatives for a match
      bool found = false;
      for (final alternative in alternatives) {
        if (alternative['name'].toString().toLowerCase() == lowercaseName) {
          found = true;
          break;
        }
      }

      // If medicine is found in alternatives, return generic info
      if (found) {
        return {
          'genericName': genericName,
          'description': medicineData['description'],
          'alternatives': List<Map<String, dynamic>>.from(alternatives),
        };
      }
    }

    // If no exact match found, try partial matching
    for (final entry in MedicineData.genericMedicines.entries) {
      final genericName = entry.key;
      final medicineData = entry.value;

      // Check if this medicine might partially match the alternatives list
      final List<Map<String, dynamic>> alternatives =
          medicineData['alternatives'];

      // Search through alternatives for a partial match
      bool found = false;
      for (final alternative in alternatives) {
        final altName = alternative['name'].toString().toLowerCase();
        if (altName.contains(lowercaseName) ||
            lowercaseName.contains(altName)) {
          found = true;
          break;
        }
      }

      // If medicine is found in alternatives, return generic info
      if (found) {
        return {
          'genericName': genericName,
          'description': medicineData['description'],
          'alternatives': List<Map<String, dynamic>>.from(alternatives),
        };
      }
    }

    return null;
  }

  /// Filter out the original medicine from the alternatives list
  void _filterOutOriginalMedicine(Map<String, dynamic> medicineInfo, String originalMedicine) {
    final List<dynamic> alternatives = medicineInfo['alternatives'];
    final String lowerOriginalName = originalMedicine.toLowerCase();
    
    // Filter out the original medicine from alternatives
    medicineInfo['alternatives'] = alternatives.where((alternative) {
      String altName;
      if (alternative is Map) {
        altName = alternative['name'].toString().toLowerCase();
      } else {
        altName = alternative.toString().toLowerCase();
      }
      
      return altName != lowerOriginalName;
    }).toList();
  }

  /// Get default response when parsing fails
  Map<String, dynamic> _getDefaultResponse({String? medicineName}) {
    return {
      'originalMedicine': medicineName ?? 'Unknown',
      'genericName': 'Unable to identify',
      'description':
          'Could not retrieve information for ${medicineName ?? "this medicine"}.',
      'alternatives': []
    };
  }
}

class MedicineFinderException implements Exception {
  const MedicineFinderException([this.message = 'Unknown problem']);
  final String message;
  @override
  String toString() => 'MedicineFinderException: $message';
}