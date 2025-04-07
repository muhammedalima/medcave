import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:medcave/main/features/ambulance_tracking/presentation/pages/driver/ambulance_driver_active.dart';
import 'package:medcave/main/features/ambulance_tracking/presentation/pages/driver/ambulance_driver_page.dart';

class AmbulanceDriverWrapper extends StatefulWidget {
  const AmbulanceDriverWrapper({Key? key}) : super(key: key);

  @override
  State<AmbulanceDriverWrapper> createState() => _AmbulanceDriverWrapperState();
}

class _AmbulanceDriverWrapperState extends State<AmbulanceDriverWrapper> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String? activeRideId;
  Map<String, dynamic>? activeRideData;
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkForActiveRide();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkForActiveRide() async {
    try {
      final String driverId = _auth.currentUser?.uid ?? '';

      if (driverId.isEmpty) {
        if (kDebugMode) {
          print('Driver not authenticated');
        }
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Listen for active rides where this driver is assigned
      // Using only 'accepted' status to match the database logic
      _subscription = _firestore
          .collection('ambulanceRequests')
          .where('assignedDriverId', isEqualTo: driverId)
          .where('status',
              isEqualTo: 'accepted') // Only accepted rides are active
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          // Found an active ride
          final doc = snapshot.docs.first;
          setState(() {
            activeRideId = doc.id;
            activeRideData = {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id, // Add the document ID to the data
            };
            isLoading = false;
          });
          if (kDebugMode) {
            print('Found active ride with ID: $activeRideId');
          }
        } else {
          // No active rides
          setState(() {
            activeRideId = null;
            activeRideData = null;
            isLoading = false;
          });
          if (kDebugMode) {
            print('No active rides found');
          }
        }
      }, onError: (e) {
        if (kDebugMode) {
          print('Error checking for active rides: $e');
        }
        setState(() {
          isLoading = false;
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('Exception in _checkForActiveRide: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method to get additional driver details if needed
  Future<Map<String, dynamic>?> _getDriverDetails(String driverId) async {
    try {
      final driverDoc =
          await _firestore.collection('users').doc(driverId).get();
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If there's an active ride, show the active screen
    if (activeRideId != null && activeRideData != null) {
      return AmbulanceDriverScreenActive(
        rideId: activeRideId!,
        rideData: activeRideData!,
      );
    }

    // Otherwise, show the regular screen
    return AmbulanceDriverScreen();
  }
}
