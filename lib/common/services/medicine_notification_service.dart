// File: lib/common/database/service/medicine_service_extension.dart

import 'package:flutter/foundation.dart';
import 'package:medcave/common/database/model/User/medicine/user_medicine_db.dart';
import 'package:medcave/common/database/service/medcine_services.dart';

/// Extension on MedicineService to provide simplified helper methods
/// These are now just wrapper functions around the main service methods
/// to maintain backward compatibility with existing code
extension MedicineServiceNotificationExtension on MedicineService {
  /// Add a medicine - wrapper for backward compatibility
  Future<String> addMedicineWithNotification(Medicine medicine) async {
    try {
      // Use the main service method which already handles notifications
      return addMedicine(medicine);
    } catch (e) {
      if (kDebugMode) {
        print('Error in addMedicineWithNotification: $e');
      }
      rethrow;
    }
  }

  /// Add multiple medicines - wrapper for backward compatibility
  Future<List<String>> addMedicinesWithNotification(
      List<Medicine> medicines) async {
    try {
      // Use the main service method which already handles notifications
      return addMedicines(medicines);
    } catch (e) {
      if (kDebugMode) {
        print('Error in addMedicinesWithNotification: $e');
      }
      rethrow;
    }
  }

  /// Update a medicine - wrapper for backward compatibility
  Future<void> updateMedicineWithNotification(Medicine medicine) async {
    try {
      // Use the main service method which already handles notifications
      await updateMedicine(medicine);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateMedicineWithNotification: $e');
      }
      rethrow;
    }
  }

  /// Delete a medicine - wrapper for backward compatibility
  Future<void> deleteMedicineWithNotification(String medicineId) async {
    try {
      // Use the main service method which already handles notifications
      await deleteMedicine(medicineId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in deleteMedicineWithNotification: $e');
      }
      rethrow;
    }
  }

  /// Update notification setting - wrapper for backward compatibility
  Future<void> updateMedicineNotificationWithRefresh(
      String medicineId, bool notify) async {
    try {
      // Use the main service method which already handles notifications
      await updateMedicineNotification(medicineId, notify);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateMedicineNotificationWithRefresh: $e');
      }
      rethrow;
    }
  }
}