import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medcave/main/features/ambulance_tracking/presentation/pages/driver/widget/location_distance.dart';

class AmbulanceDriverScreenActive extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;

  const AmbulanceDriverScreenActive({
    Key? key,
    required this.rideId,
    required this.rideData,
  }) : super(key: key);

  @override
  State<AmbulanceDriverScreenActive> createState() =>
      _AmbulanceDriverScreenActiveState();
}

class _AmbulanceDriverScreenActiveState
    extends State<AmbulanceDriverScreenActive> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  late Map<String, dynamic> _rideData;
  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  Timer? _locationUpdateTimer;

  // Driver location
  double _driverLatitude = 0.0;
  double _driverLongitude = 0.0;

  // Patient/pickup location
  double _patientLatitude = 0.0;
  double _patientLongitude = 0.0;

  // Destination
  String _destination = "";

  // Distance calculation
  String _distanceToPickup = "Calculating...";
  String _estimatedTime = "Calculating...";

  @override
  void initState() {
    super.initState();
    _rideData = widget.rideData;
    _listenToRideUpdates();
    _extractLocationData();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _extractLocationData() {
    // Extract pickup location
    final locationData = _rideData['location'] as Map<String, dynamic>? ?? {};

    // Try to get latitude/longitude from the location data
    if (locationData.containsKey('latitude') &&
        locationData.containsKey('longitude')) {
      _patientLatitude = locationData['latitude'] ?? 0.0;
      _patientLongitude = locationData['longitude'] ?? 0.0;
    }
    // If not found, try getting from the GeoPoint format which is sometimes used in Firestore
    else if (locationData.containsKey('geopoint')) {
      final geoPoint = locationData['geopoint'];
      if (geoPoint != null) {
        _patientLatitude = geoPoint.latitude ?? 0.0;
        _patientLongitude = geoPoint.longitude ?? 0.0;
      }
    }

    // If coordinates are still not found, log an error
    if (_patientLatitude == 0.0 && _patientLongitude == 0.0 && kDebugMode) {
      if (kDebugMode) {
        print('Warning: Patient coordinates not found in location data');
        print('Location data: $locationData');
      }
    }

    // Extract destination if available, but we won't display it anymore
    _destination = _rideData['destination'] ?? '';

    // Initial driver location retrieval
    _getCurrentLocation();
  }

  void _listenToRideUpdates() {
    _rideSubscription = _firestore
        .collection('ambulanceRequests')
        .doc(widget.rideId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _rideData = {
            ...snapshot.data() as Map<String, dynamic>,
            'id': snapshot.id,
          };
          _extractLocationData();
        });
      }
    }, onError: (e) {
      if (kDebugMode) {
        print('Error listening to ride updates: $e');
      }
    });
  }

  // Initialize timer to update location every 10 seconds
  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _getCurrentLocation();
      _updateDriverLocationInFirestore();
      _calculateDistanceAndTime();
    });
  }

  // Get current driver location
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _driverLatitude = position.latitude;
        _driverLongitude = position.longitude;
      });

      _calculateDistanceAndTime();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
    }
  }

  // Calculate distance and estimated time
  void _calculateDistanceAndTime() {
    if (_patientLatitude != 0.0 &&
        _patientLongitude != 0.0 &&
        _driverLatitude != 0.0 &&
        _driverLongitude != 0.0) {
      double distanceInMeters = Geolocator.distanceBetween(
        _driverLatitude,
        _driverLongitude,
        _patientLatitude,
        _patientLongitude,
      );

      // Convert to kilometers
      double distanceInKm = distanceInMeters / 1000;

      // Estimate time: assuming average speed of 40 km/h for ambulance in traffic
      // Adjust speed based on distance - faster in highways, slower in city
      double averageSpeedKmh = 40;
      if (distanceInKm > 10) {
        // For longer distances, assume some highway travel at higher speeds
        averageSpeedKmh = 55;
      } else if (distanceInKm < 3) {
        // For shorter distances, assume city traffic
        averageSpeedKmh = 30;
      }

      double timeInHours = distanceInKm / averageSpeedKmh;
      int timeInMinutes = (timeInHours * 60).round();

      setState(() {
        _distanceToPickup = "${distanceInKm.toStringAsFixed(1)} km";
        _estimatedTime = "$timeInMinutes min";

        // Log for debugging
        if (kDebugMode) {
          print('Distance updated: $_distanceToPickup, ETA: $_estimatedTime');
          print('Driver coordinates: $_driverLatitude, $_driverLongitude');
          print('Patient coordinates: $_patientLatitude, $_patientLongitude');
        }
      });
    }
  }

  // Update driver location in Firestore
  Future<void> _updateDriverLocationInFirestore() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      // Update driver location in the drivers collection
      await _firestore.collection('drivers').doc(user.uid).update({
        'location': {
          'latitude': _driverLatitude,
          'longitude': _driverLongitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });

      // Update driver location in the ambulance request
      await _firestore
          .collection('ambulanceRequests')
          .doc(widget.rideId)
          .update({
        'driverLocation': {
          'latitude': _driverLatitude,
          'longitude': _driverLongitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating driver location: $e');
      }
    }
  }

  void _handleComplete() async {
    try {
      setState(() {
        isLoading = true;
      });

      await _firestore
          .collection('ambulanceRequests')
          .doc(widget.rideId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        // Show completion message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride completed successfully')),
        );

        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error completing ride: $e');
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete ride: $e')),
        );
      }
    }
  }

  void _handleCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              try {
                setState(() {
                  isLoading = true;
                });

                await _firestore
                    .collection('ambulanceRequests')
                    .doc(widget.rideId)
                    .update({
                  'status': 'cancelled',
                  'cancelledAt': FieldValue.serverTimestamp(),
                  'cancellationReason': 'Cancelled by driver',
                });

                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ride cancelled')),
                  );

                  Navigator.pop(context); // Return to previous screen
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Error cancelling ride: $e');
                }

                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling ride: $e')),
                  );
                }
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract patient information
    final String patientName = _rideData['userName'] ?? 'Unknown';
    final String patientPhone = _rideData['phoneNumber'] ?? 'Unknown';

    // Extract location data
    final locationData = _rideData['location'] as Map<String, dynamic>? ?? {};
    final String address =
        locationData['address'] as String? ?? 'Unknown location';

    // Extract emergency data
    final emergencyData = _rideData['emergency'] as Map<String, dynamic>? ?? {};
    final String emergencyReason = emergencyData['detailedReason'] ??
        emergencyData['description'] ??
        'Emergency';

    // Format timestamp
    Timestamp? timestamp = _rideData['timestamp'] as Timestamp?;
    DateTime requestTime = timestamp?.toDate() ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Ride'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location and Distance Card
                          LocationDistanceWidget(
                            destination: _destination,
                            address: address,
                            distanceToPickup: _distanceToPickup,
                            estimatedTime: _estimatedTime,
                            driverLatitude: _driverLatitude,
                            driverLongitude: _driverLongitude,
                            pickupLatitude: _patientLatitude,
                            pickupLongitude: _patientLongitude,
                          ),

                          // Main information card
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Patient info
                                const Text(
                                  'Patient Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      patientName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const Text(' • '),
                                    const Icon(Icons.phone, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      patientPhone,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Emergency reason
                                const Text(
                                  'Reason for request',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  emergencyReason,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // First row of condition cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildConditionCard(
                                        'Severity',
                                        emergencyData['severity'] ?? 'Critical',
                                        'image1.gif',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildConditionCard(
                                        'Type',
                                        emergencyData['reason'] ??
                                            emergencyData['type'] ??
                                            'Cardiac',
                                        'image2.gif',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildConditionCard(
                                        'Consciousness',
                                        emergencyData['consciousness'] ??
                                            'Normal',
                                        'image3.gif',
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Condition Cards - Second row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildConditionCard(
                                        'Breathing',
                                        emergencyData['breathing'] ?? 'Normal',
                                        'image4.gif',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: _buildConditionCard(
                                        'Visible Injuries',
                                        emergencyData['visibleInjuries'] ??
                                            'None reported',
                                        'image5.gif',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Time and date card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time & Date',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTime(requestTime),
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(requestTime),
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Additional emergency information section
                          if (emergencyData['customDescription'] != null)
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Additional Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    emergencyData['customDescription'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom action buttons
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _handleComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Completed',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _handleCancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatTime(DateTime time) {
    return time.hour > 12
        ? '${time.hour - 12}:${time.minute.toString().padLeft(2, '0')} PM'
        : '${time.hour}:${time.minute.toString().padLeft(2, '0')} AM';
  }

  String _formatDate(DateTime date) {
    final List<String> months = [
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
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  Widget _buildConditionCard(String title, String value, String imageAsset) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/gifimage/$imageAsset',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) => Icon(
              _getIconForCondition(title),
              color: _getColorForCondition(title),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getIconForCondition(String title) {
    switch (title) {
      case 'Severity':
        return Icons.warning;
      case 'Type':
        return Icons.favorite;
      case 'Consciousness':
        return Icons.remove_red_eye;
      case 'Breathing':
        return Icons.air;
      case 'Visible Injuries':
        return Icons.healing;
      default:
        return Icons.info;
    }
  }

  Color _getColorForCondition(String title) {
    switch (title) {
      case 'Severity':
        return Colors.red;
      case 'Type':
        return Colors.blue;
      case 'Consciousness':
        return Colors.green;
      case 'Breathing':
        return Colors.purple;
      case 'Visible Injuries':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
