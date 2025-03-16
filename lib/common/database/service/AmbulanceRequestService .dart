import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AmbulanceRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current driver ID
  String get driverId => _auth.currentUser?.uid ?? '';

  // Function to fetch past ride request IDs for the current driver
  Future<List<String>> getPastRideRequestIdsForDriver() async {
    try {
      if (driverId.isEmpty) {
        debugPrint('Driver ID is empty');
        return [];
      }

      // Query Firestore for all completed requests assigned to this driver
      final QuerySnapshot snapshot = await _firestore
          .collection('ambulanceRequests')
          .where('assignedDriverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          //.orderBy('completedAt', descending: true)
          .get();

      // Extract document IDs from the query result
      final List<String> pastRideRequestIds =
          snapshot.docs.map((doc) => doc.id).toList();

      debugPrint(
          'Found ${pastRideRequestIds.length} past rides for driver: $driverId');
      return pastRideRequestIds;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching past ride request IDs: $e');
      }
      return [];
    }
  }

  // Function to fetch current request IDs for the driver
  Future<List<String>> getCurrentRequestIdsForDriver() async {
    try {
      if (driverId.isEmpty) {
        debugPrint('Driver ID is empty');
        return [];
      }

      // Query Firestore for pending requests assigned to this driver
      final QuerySnapshot snapshot = await _firestore
          .collection('ambulanceRequests')
          .where('assignedDriverId', isEqualTo: "")
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .get();

      // Extract document IDs from the query result
      final List<String> currentRequestIds =
          snapshot.docs.map((doc) => doc.id).toList();

      debugPrint(
          'Found ${currentRequestIds.length} pending requests for driver: $driverId');
      return currentRequestIds;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching current request IDs: $e');
      }
      return [];
    }
  }

  // Function to fetch multiple requests based on request IDs
  Future<List<Map<String, dynamic>>> getRequestsByIds(
      List<String> requestIds) async {
    try {
      if (requestIds.isEmpty) {
        return [];
      }

      final List<Map<String, dynamic>> requests = [];

      // Use batched reads for efficiency
      final chunks = _chunkList(
          requestIds, 10); // Firestore has a limit of 10 for 'in' queries

      for (final chunk in chunks) {
        final QuerySnapshot snapshot = await _firestore
            .collection('ambulanceRequests')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          // Add the document ID to the data
          requests.add({...data, 'id': doc.id});
        }
      }

      return requests;
    } catch (e) {
      if (e is FirebaseException) {
        if (kDebugMode) {
          print('Firebase Error fetching requests: ${e.code} - ${e.message}');
        }
      } else {
        if (kDebugMode) {
          print('Error fetching requests: $e');
        }
      }
      return [];
    }
  }

  // Helper function to chunk a list into smaller lists
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
          i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  // Format request data for UI display
  Map<String, dynamic> formatRequestForUI(Map<String, dynamic> request) {
    // Extract timestamp and convert to DateTime
    final Timestamp timestamp = request['timestamp'] as Timestamp? ??
        Timestamp.fromDate(DateTime.now());
    final DateTime dateTime = timestamp.toDate();

    // Format date as "DD MMM"
    final String date =
        "${dateTime.day} ${_getMonthAbbreviation(dateTime.month)}";

    // Format time as "h:mmAM/PM"
    final String hour = dateTime.hour > 12
        ? (dateTime.hour - 12).toString()
        : dateTime.hour.toString();
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final String time = "$hour:$minute$period";

    // Get destination from location data if available
    final Map<String, dynamic>? location =
        request['location'] as Map<String, dynamic>?;
    final String destination = location != null && location['address'] != null
        ? "To ${location['address']}"
        : "To destination";

    // Get emergency reason if available
    final Map<String, dynamic>? emergency =
        request['emergency'] as Map<String, dynamic>?;
    final String reason = emergency != null && emergency['reason'] != null
        ? emergency['reason']
        : "Emergency";

    return {
      'id': request['id'],
      'destination': destination,
      'date': date,
      'time': time,
      'reason': reason,
      'status': request['status'] ?? 'unknown',
      'userName': request['userName'] ?? 'Unknown',
      'phoneNumber': request['phoneNumber'] ?? 'Unknown',
      // Store the complete original data for passing to detail view
      'completeData': request,
    };
  }

  // Helper to get month abbreviation
  String _getMonthAbbreviation(int month) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // Get current requests
  Future<List<Map<String, dynamic>>> getCurrentRequests() async {
    final currentRequestIds = await getCurrentRequestIdsForDriver();
    final requests = await getRequestsByIds(currentRequestIds);
    return requests.map((request) => formatRequestForUI(request)).toList();
  }

  // Get past rides
  Future<List<Map<String, dynamic>>> getPastRides() async {
    final pastRideRequestIds = await getPastRideRequestIdsForDriver();
    final requests = await getRequestsByIds(pastRideRequestIds);
    return requests.map((request) => formatRequestForUI(request)).toList();
  }
}