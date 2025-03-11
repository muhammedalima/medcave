import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medcave/Users/Mobilescreens/commonWidget/customnavbar.dart';
import 'package:medcave/config/colors/appcolor.dart';

class AmbulanceDetailDriver extends StatelessWidget {
  final Map<String, dynamic> completeData;
  final String requestId;
  final bool isPastRide;  // Added parameter to identify past rides

  const AmbulanceDetailDriver({
    super.key,  
    required this.completeData,
    required this.requestId,
    this.isPastRide = false,  // Default to false for backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    // Extract patient information
    final String patientName = completeData['userName'] ?? 'Unknown';
    final String patientPhone = completeData['userPhone'] ?? 'Unknown';

    // Extract location data
    final locationData =
        completeData['location'] as Map<String, dynamic>? ?? {};
    final address = locationData['address'] as String? ?? 'Unknown location';
    final destination = completeData['destination'] ?? 'Kochi';

    // Extract emergency data
    final emergencyData =
        completeData['emergency'] as Map<String, dynamic>? ?? {};

    // Format timestamp
    Timestamp? timestamp = completeData['timestamp'] as Timestamp?;
    DateTime requestTime = timestamp?.toDate() ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColor.backgroundWhite,
      appBar: CustomAppBar(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with destination
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            'To $destination',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'request from $patientName',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            patientPhone,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Emergency reason
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reason for request',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            emergencyData['detailedReason'] ??
                                emergencyData['description'] ??
                                'Heart attack',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // First row of condition cards
                          Row(
                            children: [
                              _buildConditionCard(
                                'Severity',
                                emergencyData['severity'] ?? 'Critical',
                                Icons.warning,
                                Colors.red,
                              ),
                              const SizedBox(width: 8),
                              _buildConditionCard(
                                'Type',
                                emergencyData['reason'] ??
                                    emergencyData['type'] ??
                                    'Cardiac',
                                Icons.favorite,
                                Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              _buildConditionCard(
                                'Consciousness',
                                emergencyData['consciousness'] ?? 'Normal',
                                Icons.remove_red_eye,
                                Colors.green,
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Second row of condition cards
                          Row(
                            children: [
                              _buildConditionCard(
                                'Breathing',
                                emergencyData['breathing'] ?? 'Normal',
                                Icons.air,
                                Colors.purple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: _buildConditionCard(
                                  'Visible Injuries',
                                  emergencyData['visibleInjuries'] ??
                                      'Bleeding, Fractures',
                                  Icons.healing,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Time and date
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
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
                                requestTime.hour > 12
                                    ? '${requestTime.hour - 12}:${requestTime.minute.toString().padLeft(2, '0')} PM'
                                    : '${requestTime.hour}:${requestTime.minute.toString().padLeft(2, '0')} AM',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 36),
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

                    // Route traveled section
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Text(
                        'Route Traveled',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Image.asset(
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
                      ),
                    ),

                    // Incident description
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action buttons - Only show if not a past ride
            if (!isPastRide)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleAccept(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleReject(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            // For past rides, show a "Back" button instead
            if (isPastRide)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Back to Dashboard',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
        desiredAccuracy: LocationAccuracy.high
      );
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
      'driverName': 'Current Driver', // This should be replaced with actual driver name from user profile
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
                'rejectedBy': FieldValue.arrayUnion([currentUser.uid]), // Track who rejected using actual driver ID
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

  Widget _buildConditionCard(
      String title, String value, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
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
      ),
    );
  }
}