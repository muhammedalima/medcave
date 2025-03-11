import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class AmbulanceDetailDriver extends StatelessWidget {
  final Map<String, dynamic> completeData;
  final String requestId;
  final bool isPastRide;

  const AmbulanceDetailDriver({
    super.key,
    required this.completeData,
    required this.requestId,
    this.isPastRide = false,
  });

  @override
  Widget build(BuildContext context) {
    // Extract patient information
    final String patientName = completeData['userName'] ?? 'Unknown';
    final String patientPhone =
        completeData['phoneNumber'] ?? completeData['userPhone'] ?? 'Unknown';

    // Extract location data
    final locationData =
        completeData['location'] as Map<String, dynamic>? ?? {};
    final address = locationData['address'] as String? ?? 'Unknown location';

    // Get coordinates for navigation
    final double latitude = locationData['latitude'] ?? 0.0;
    final double longitude = locationData['longitude'] ?? 0.0;

    // Get destination
    final String destination = completeData['destination'] ?? address;

    // Extract emergency data
    final emergencyData =
        completeData['emergency'] as Map<String, dynamic>? ?? {};
    final String emergencyReason = emergencyData['detailedReason'] ??
        emergencyData['description'] ??
        'Heart attack';

    // Format timestamp
    Timestamp? timestamp = completeData['timestamp'] as Timestamp?;
    DateTime requestTime = timestamp?.toDate() ?? DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination and Patient info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To $destination',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'request from $patientName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('•'),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _makePhoneCall(patientPhone),
                        child: Text(
                          patientPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Current Ride Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reason for request
                    Text(
                      'Reason for request',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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

                    // Condition Cards - First row
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
                            emergencyData['consciousness'] ?? 'Normal',
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
                            emergencyData['visibleInjuries'] ?? 'None reported',
                            'image5.gif',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Time & Date
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time & Date',
                      style: TextStyle(
                        fontSize: 20,
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

              // Route Traveled section
              const Text(
                'Route Traveled',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Map container
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/map_placeholder.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.map,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                      if (latitude != 0.0 && longitude != 0.0)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton.small(
                            onPressed: () =>
                                _launchMapsNavigation(latitude, longitude),
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.directions,
                                color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // About the incident
              const Text(
                'About the incident',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                emergencyData['customDescription'] ??
                    "There's been a car accident where a vehicle collided with a tree at high speed. The driver is unconscious with a possible head injury and chest trauma, while the passenger is awake but in severe pain, likely with a leg fracture. The impact was significant, and immediate medical attention is required to assess and stabilize both individuals. Please confirm the availability of an ambulance with advanced life support to respond quickly.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      // Bottom buttons
      bottomNavigationBar: !isPastRide
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleAccept(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFEE16F), // Light amber color
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleReject(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Back to Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // Launch Google Maps for navigation
  void _launchMapsNavigation(double latitude, double longitude) async {
    final String googleMapsUrl =
        'google.navigation:q=$latitude,$longitude&mode=d';
    final String fallbackUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';

    try {
      final bool launched = await launch(googleMapsUrl);
      if (!launched) {
        await launch(fallbackUrl);
      }
    } catch (e) {
      await launch(fallbackUrl);
    }
  }

  // Make a phone call
  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launch(phoneUri.toString());
    } catch (e) {
      // Handle error
      if (kDebugMode) {
        print('Could not launch phone: $e');
      }
    }
  }

  void _handleAccept(BuildContext context) async {
    try {
      // Get current driver ID
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Not authenticated')),
        );
        return;
      }

      // Get current location of the driver
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
        return;
      }

      // Update the request status in Firestore
      await FirebaseFirestore.instance
          .collection('ambulanceRequests')
          .doc(requestId)
          .update({
        'status': 'accepted',
        'assignedDriverId': currentUser.uid,
        'driverName':
            'Current Driver', // This should be replaced with actual driver name
        'acceptedTime': Timestamp.now(),
        'estimatedArrivalTime': '10 minutes', // This should be calculated
        'startingLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'heading': position.heading,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted successfully')),
      );
      Navigator.pop(context);
    } catch (error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting request: $error')),
      );
    }
  }

  void _handleReject(BuildContext context) {
    // Show confirmation dialog and update status if confirmed
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: const Text('Are you sure you want to reject this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              try {
                // Get current driver ID
                final User? currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Not authenticated')),
                  );
                  return;
                }

                // Update Firestore
                await FirebaseFirestore.instance
                    .collection('ambulanceRequests')
                    .doc(requestId)
                    .update({
                  'status': 'available', // Reset to available for other drivers
                  'rejectedBy': FieldValue.arrayUnion(
                      [currentUser.uid]), // Track who rejected
                });

                Navigator.pop(context); // Return to previous screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request rejected')),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error rejecting request: $error')),
                );
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
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
