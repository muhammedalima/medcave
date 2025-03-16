import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AmbulanceRequestDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new ambulance request in the database
  Future<String> createAmbulanceRequest({
    required Map<String, dynamic> emergencyData,
    required Map<String, dynamic> locationData,
  }) async {
    try {
      // Get current user ID
      final String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Make sure emergencyData contains both customDescription and detailedReason
      // If customDescription is missing but description is present, use that
      if (!emergencyData.containsKey('customDescription') && emergencyData.containsKey('description')) {
        emergencyData['customDescription'] = emergencyData['description'];
      }
      
      // If no detailedReason but we have reason, use that
      if (!emergencyData.containsKey('detailedReason') && emergencyData.containsKey('reason')) {
        emergencyData['detailedReason'] = emergencyData['reason'];
      }

      // Create request object
      final requestData = {
        'userId': userId,
        'userName': userData['name'] ?? 'Unknown',
        'phoneNumber': userData['phoneNumber'] ?? 'Unknown',
        'emergency': emergencyData,
        'location': locationData,
        'status': 'pending', // initial status: pending, accepted, completed, cancelled
        'timestamp': FieldValue.serverTimestamp(),
        'assignedDriverId': '', // Will be filled when a driver accepts
        'estimatedArrivalTime': null,
      };

      // Add document to Firestore
      final docRef = await _firestore.collection('ambulanceRequests').add(requestData);
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating ambulance request: $e');
      }
      throw Exception('Failed to create ambulance request: ${e.toString()}');
    }
  }

  // Get a specific ambulance request with driver details
  Future<Map<String, dynamic>> getRequest(String requestId) async {
    try {
      final doc = await _firestore.collection('ambulanceRequests').doc(requestId).get();
      if (!doc.exists) {
        throw Exception('Request not found');
      }
      
      final requestData = doc.data() as Map<String, dynamic>;
      
      // If there's an assigned driver, fetch their details
      if (requestData['assignedDriverId'] != null && requestData['assignedDriverId'].isNotEmpty) {
        final driverData = await getDriverDetails(requestData['assignedDriverId']);
        if (driverData != null) {
          // Add driver details to the request data
          requestData['driverName'] = driverData['name'];
          requestData['driverPhoneNumber'] = driverData['phoneNumber'];
        }
      }
      
      return requestData;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching ambulance request: $e');
      }
      throw Exception('Failed to fetch ambulance request: ${e.toString()}');
    }
  }

  // Helper method to get driver details from users collection
  Future<Map<String, dynamic>?> getDriverDetails(String driverId) async {
    try {
      final driverDoc = await _firestore.collection('users').doc(driverId).get();
      if (driverDoc.exists) {
        return driverDoc.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching driver details: $e');
      }
      return null;
    }
  }

  // Get all requests for the current user
  Stream<QuerySnapshot> getUserRequests() {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    
    return _firestore
        .collection('ambulanceRequests')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get latest ambulance request status
  Future<Map<String, dynamic>> getLatestRequestStatus() async {
    try {
      final String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        return {'status': 'no_request', 'message': "You haven't searched yet!"};
      }
      
      final QuerySnapshot snapshot = await _firestore
          .collection('ambulanceRequests')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return {'status': 'no_request', 'message': "You haven't searched yet!"};
      }
      
      final latestRequest = snapshot.docs.first.data() as Map<String, dynamic>;
      final String status = latestRequest['status'] ?? 'unknown';
      
      // If the request is completed, check the time difference
      if (status == 'completed') {
        final Timestamp? completedAt = latestRequest['completedAt'];
        
        if (completedAt != null) {
          final DateTime completionTime = completedAt.toDate();
          final DateTime thirtyMinutesAgo = DateTime.now().subtract(const Duration(minutes: 30));
          
          if (completionTime.isBefore(thirtyMinutesAgo)) {
            return {'status': 'no_recent_request', 'message': "You haven't searched yet!"};
          }
        }
        
        return {'status': status, 'message': 'Request new ambulance'};
      }
      
      // Return appropriate messages for each status
      String message;
      switch (status) {
        case 'pending':
          message = 'Searching for ambulance...';
          break;
        case 'accepted':
          message = 'Ambulance on the way';
          break;
        case 'cancelled':
          message = 'Request new ambulance';
          break;
        case 'unknown':
          message = 'Request an ambulance';
          break;
        default:
          message = 'Request an ambulance';
      }
      
      return {'status': status, 'message': message};
    } catch (e) {
      if (kDebugMode) {
        print('Error getting latest request status: $e');
      }
      // Instead of returning "Try again", return a default message
      return {'status': 'error', 'message': 'Request an ambulance'};
    }
  }

  // Get pending requests (for ambulance drivers)
  Stream<QuerySnapshot> getPendingRequests() {
    return _firestore
        .collection('ambulanceRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Accept a request (for ambulance drivers)
  Future<void> acceptRequest(String requestId, String driverId, String estimatedArrivalTime) async {
    try {
      // First get the driver details from users collection
      final driverDoc = await _firestore.collection('users').doc(driverId).get();
      if (!driverDoc.exists) {
        throw Exception('Driver profile not found');
      }
      
      final driverData = driverDoc.data() as Map<String, dynamic>;
      final String driverName = driverData['name'] ?? 'Unknown';
      final String driverPhoneNumber = driverData['phoneNumber'] ?? 'Unknown';
      
      await _firestore.collection('ambulanceRequests').doc(requestId).update({
        'status': 'accepted',
        'assignedDriverId': driverId,
        'driverName': driverName,
        'driverPhoneNumber': driverPhoneNumber,
        'estimatedArrivalTime': estimatedArrivalTime,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting request: $e');
      }
      throw Exception('Failed to accept request: ${e.toString()}');
    }
  }

  // Update request status
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _firestore.collection('ambulanceRequests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating request status: $e');
      }
      throw Exception('Failed to update request status: ${e.toString()}');
    }
  }

  // Update driver location
  Future<void> updateDriverLocation(String requestId, LatLng location) async {
    try {
      await _firestore.collection('ambulanceRequests').doc(requestId).update({
        'driverLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating driver location: $e');
      }
      throw Exception('Failed to update driver location: ${e.toString()}');
    }
  }

  // Cancel a request
  Future<void> cancelRequest(String requestId, String reason) async {
    try {
      await _firestore.collection('ambulanceRequests').doc(requestId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling request: $e');
      }
      throw Exception('Failed to cancel request: ${e.toString()}');
    }
  }

  // Complete a request
  Future<void> completeRequest(String requestId) async {
    try {
      await _firestore.collection('ambulanceRequests').doc(requestId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error completing request: $e');
      }
      throw Exception('Failed to complete request: ${e.toString()}');
    }
  }
  
  // Fetch multiple requests by their IDs
  Future<List<Map<String, dynamic>>> getRequestsByIds(List<String> requestIds) async {
    try {
      final List<Map<String, dynamic>> requests = [];
      
      // Use batched reads for efficiency
      final chunks = _chunkList(requestIds, 10); // Firestore has a limit of 10 for 'in' queries
      
      for (final chunk in chunks) {
        final QuerySnapshot snapshot = await _firestore
            .collection('ambulanceRequests')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
            
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          // Add the document ID to the data
          Map<String, dynamic> requestWithId = {
            ...data,
            'id': doc.id
          };
          
          // If there's an assigned driver, fetch their details
          if (data['assignedDriverId'] != null && data['assignedDriverId'].isNotEmpty) {
            final driverData = await getDriverDetails(data['assignedDriverId']);
            if (driverData != null) {
              requestWithId['driverName'] = driverData['name'];
              requestWithId['driverPhoneNumber'] = driverData['phoneNumber'];
            }
          }
          
          requests.add(requestWithId);
        }
      }
      
      return requests;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching requests by IDs: $e');
      }
      return [];
    }
  }
  
  // Helper function to chunk a list into smaller lists
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize)
      );
    }
    return chunks;
  }
}