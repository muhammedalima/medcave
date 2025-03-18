// File: lib/common/services/driver_database.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Correct import for dart:math
import 'dart:math' as math;

// Constants for SharedPreferences keys
const String KEY_DRIVER_ID = 'driver_id';
const String KEY_IS_DRIVER_ACTIVE = 'is_driver_active';

// Driver data model
class DriverData {
  final String driverId;
  final String userId;
  final String? driverLicense;
  final String? vehicleRegistrationNumber;
  final String? ambulanceType;
  final List<String>? equipment;
  final bool isDriverActive;
  
  DriverData({
    this.driverId = '',
    this.userId = '',
    this.driverLicense = '',
    this.vehicleRegistrationNumber = '',
    this.ambulanceType = '',
    this.equipment = const [],
    this.isDriverActive = false,
  });
}

class DriverDatabase {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Save driver data to Firestore
  static Future<bool> saveDriverData(DriverData driverData) async {
    try {
      if (kDebugMode) {
        print('Saving driver data...');
      }
      
      final user = _auth.currentUser;
      if (user != null) {
        // Get a reference to the drivers collection
        final driverRef = _firestore.collection('drivers').doc(user.uid);
        
        await driverRef.set({
          'driverId': user.uid,
          'userId': user.uid,
          'driverLicense': driverData.driverLicense,
          'vehicleRegistrationNumber': driverData.vehicleRegistrationNumber,
          'ambulanceType': driverData.ambulanceType,
          'equipment': driverData.equipment,
          'isDriverActive': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Also update SharedPreferences to keep states in sync
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(KEY_IS_DRIVER_ACTIVE, false);
        
        if (kDebugMode) {
          print('Driver data saved successfully');
        }
        
        return true;
      }
      
      if (kDebugMode) {
        print('No user logged in, cannot save driver data');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving driver data: $e');
      }
      return false;
    }
  }
  
  // Get current driver data
  static Future<Map<String, dynamic>?> getCurrentDriverData() async {
    try {
      if (kDebugMode) {
        print('Getting current driver data...');
      }
      
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('drivers').doc(user.uid).get();
        if (doc.exists) {
          if (kDebugMode) {
            print('Driver data retrieved successfully');
          }
          return doc.data();
        } else {
          if (kDebugMode) {
            print('Driver document does not exist');
          }
        }
      } else {
        if (kDebugMode) {
          print('No user logged in, cannot get driver data');
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting driver data: $e');
      }
      return null;
    }
  }
  
  // Update driver active status
  static Future<bool> updateDriverActiveStatus(bool isActive) async {
    try {
      if (kDebugMode) {
        print('Updating driver active status to: $isActive');
      }
      
      final user = _auth.currentUser;
      if (user != null) {
        // 1. Update Firestore
        await _firestore.collection('drivers').doc(user.uid).update({
          'isDriverActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        if (kDebugMode) {
          print('Driver active status updated in Firestore: $isActive');
        }
        
        // 2. Update SharedPreferences to keep them in sync
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(KEY_IS_DRIVER_ACTIVE, isActive);
        
        if (kDebugMode) {
          print('Updated SharedPreferences with is_driver_active = $isActive');
        }
        
        return true;
      }
      
      if (kDebugMode) {
        print('No user logged in, cannot update driver status');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating driver status: $e');
      }
      return false;
    }
  }
  
  // Delete driver data
  static Future<bool> deleteDriverData() async {
    try {
      if (kDebugMode) {
        print('Deleting driver data...');
      }
      
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('drivers').doc(user.uid).delete();
        
        // Also clear SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(KEY_IS_DRIVER_ACTIVE);
        
        if (kDebugMode) {
          print('Driver data deleted successfully');
        }
        return true;
      }
      
      if (kDebugMode) {
        print('No user logged in, cannot delete driver data');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting driver data: $e');
      }
      return false;
    }
  }
  
  // Update driver location
  static Future<bool> updateDriverLocation(
    String driverId,
    double latitude,
    double longitude,
    double heading,
    double speed,
    double accuracy,
  ) async {
    try {
      if (kDebugMode) {
        print('Updating driver location for ID: $driverId');
        print('Location: $latitude, $longitude');
      }
      
      // Update current location
      await _firestore.collection('drivers').doc(driverId).update({
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'heading': heading,
          'speed': speed,
          'accuracy': accuracy,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('Main location updated in Firestore');
      }
      
      // Optionally store in location history subcollection
      await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('locationHistory')
          .add({
            'latitude': latitude,
            'longitude': longitude,
            'heading': heading,
            'speed': speed,
            'accuracy': accuracy,
            'timestamp': FieldValue.serverTimestamp(),
          });
      
      if (kDebugMode) {
        print('Location history added successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating driver location: $e');
      }
      return false;
    }
  }
  
  // Get driver location history 
  static Future<List<Map<String, dynamic>>> getDriverLocationHistory(
    String driverId, 
    {DateTime? startTime, DateTime? endTime}
  ) async {
    try {
      if (kDebugMode) {
        print('Getting driver location history for ID: $driverId');
      }
      
      QuerySnapshot query;
      
      if (startTime != null && endTime != null) {
        query = await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('locationHistory')
          .where('timestamp', isGreaterThanOrEqualTo: startTime)
          .where('timestamp', isLessThanOrEqualTo: endTime)
          .orderBy('timestamp', descending: true)
          .get();
      } else {
        query = await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('locationHistory')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      }
      
      final results = query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      if (kDebugMode) {
        print('Retrieved ${results.length} location history records');
      }
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting driver location history: $e');
      }
      return [];
    }
  }
  
  // Get nearby active drivers
  static Future<List<Map<String, dynamic>>> getNearbyDrivers(
    double latitude, 
    double longitude, 
    double radiusInKm
  ) async {
    try {
      if (kDebugMode) {
        print('Getting nearby drivers within $radiusInKm km of $latitude, $longitude');
      }
      
      // This is a simplified approach. For production, consider using Firestore's
      // GeoPoint or a specialized solution like GeoFirestore
      final drivers = await _firestore
          .collection('drivers')
          .where('isDriverActive', isEqualTo: true)
          .get();
      
      if (kDebugMode) {
        print('Found ${drivers.docs.length} active drivers in total');
      }
      
      // Filter drivers by distance (simplified approach)
      final nearbyDrivers = drivers.docs
          .map((doc) => doc.data())
          .where((data) {
            if (data['location'] == null) return false;
            
            // Calculate rough distance (simplified)
            final driverLat = data['location']['latitude'] as double;
            final driverLng = data['location']['longitude'] as double;
            
            // Simple distance calculation (approximate)
            final distance = _calculateDistance(
              latitude, 
              longitude, 
              driverLat, 
              driverLng
            );
            
            return distance <= radiusInKm;
          })
          .toList();
      
      if (kDebugMode) {
        print('Found ${nearbyDrivers.length} drivers within $radiusInKm km');
      }
      
      return nearbyDrivers;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting nearby drivers: $e');
      }
      return [];
    }
  }
  
  // Helper method to calculate distance between coordinates (Haversine formula)
  static double _calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    const double earthRadius = 6371; // in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * 
        math.cos(_degreesToRadians(lat1)) * 
        math.cos(_degreesToRadians(lat2));
    
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  // Test direct location update - useful for debugging
  static Future<bool> testDirectLocationUpdate() async {
    try {
      if (kDebugMode) {
        print('Testing direct location update...');
      }
      
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('No user logged in, cannot test location update');
        }
        return false;
      }
      
      // Use a fixed test location
      const double testLat = 37.4220;
      const double testLng = -122.0841;
      
      // Update in Firestore
      await _firestore.collection('drivers').doc(user.uid).update({
        'location': {
          'latitude': testLat,
          'longitude': testLng,
          'heading': 0.0,
          'speed': 0.0,
          'accuracy': 0.0,
          'timestamp': FieldValue.serverTimestamp(),
          'testUpdate': true,
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('Direct test location update successful');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error in test direct location update: $e');
      }
      return false;
    }
  }
}

// Extensions to add math operations - no longer needed with direct math package usage
extension MathOperations on double {
  double toRadians() {
    return this * (math.pi / 180);
  }
}

const double pi = math.pi;