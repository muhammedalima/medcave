import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// Correct import for dart:math
import 'dart:math' as math;


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
        
        return true;
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
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('drivers').doc(user.uid).get();
        if (doc.exists) {
          return doc.data();
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
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('drivers').doc(user.uid).update({
          'isDriverActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
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
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('drivers').doc(user.uid).delete();
        return true;
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
      
      return query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
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
      // This is a simplified approach. For production, consider using Firestore's
      // GeoPoint or a specialized solution like GeoFirestore
      final drivers = await _firestore
          .collection('drivers')
          .where('isDriverActive', isEqualTo: true)
          .get();
      
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
        (dLat / 2).sin() * (dLat / 2).sin() +
        (dLon / 2).sin() * (dLon / 2).sin() * 
        lat1.toRadians().cos() * 
        lat2.toRadians().cos();
    
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}

// Extensions to add math operations
extension MathOperations on double {
  double toRadians() {
    return this * (pi / 180);
  }
  
  double sin() {
    return math.sin(this);
  }
  
  double cos() {
    return math.cos(this);
  }
}

double asin(double value) {
  return math.asin(value);
}

double sqrt(double value) {
  return math.sqrt(value);
}


const double pi = math.pi;