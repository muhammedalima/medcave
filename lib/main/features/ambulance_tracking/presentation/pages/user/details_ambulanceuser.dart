import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/main/commonWidget/customnavbar.dart';

class UserAmbulanceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> completeData;
  final String requestId;

  const UserAmbulanceDetailScreen({
    super.key,
    required this.completeData,
    required this.requestId,
  });

  @override
  State<UserAmbulanceDetailScreen> createState() =>
      _UserAmbulanceDetailScreenState();
}

class _UserAmbulanceDetailScreenState extends State<UserAmbulanceDetailScreen> {
  String driverName = 'Loading...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverName();
  }

  Future<void> _fetchDriverName() async {
    try {
      final String? driverId =
          widget.completeData['assignedDriverId'] as String?;

      if (driverId != null) {
        // Fetch driver data from Firestore
        final driverDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .get();

        if (driverDoc.exists) {
          // First check if there's a name field in the driver document
          final driverData = driverDoc.data() as Map<String, dynamic>;

          if (driverData.containsKey('name') && driverData['name'] != null) {
            setState(() {
              driverName = driverData['name'];
              isLoading = false;
            });
          } else {
            // If no name in driver document, fetch from users collection using userId
            final String? userId = driverData['userId'] as String?;

            if (userId != null) {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get();

              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;
                setState(() {
                  // Get the name from user data
                  driverName = userData['name'] ??
                      userData['fullName'] ??
                      'Unknown Driver';
                  isLoading = false;
                });
              } else {
                setState(() {
                  driverName = 'Unknown Driver';
                  isLoading = false;
                });
              }
            } else {
              setState(() {
                driverName = 'Unknown Driver';
                isLoading = false;
              });
            }
          }
        } else {
          setState(() {
            driverName = 'Unknown Driver';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          driverName = 'No Driver Assigned';
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching driver data: $e');
      }
      setState(() {
        driverName = 'Error Loading Driver Info';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract location data
    final locationData =
        widget.completeData['location'] as Map<String, dynamic>;
    final address = locationData['address'] as String;

    // Extract emergency data
    final emergencyData =
        widget.completeData['emergency'] as Map<String, dynamic>? ?? {};

    // Format timestamp
    Timestamp? timestamp = widget.completeData['timestamp'] as Timestamp?;
    DateTime requestTime = timestamp?.toDate() ?? DateTime.now();

    return Scaffold(
      appBar: CustomAppBar(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 12,
              ),
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Issue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emergencyData['detailedReason'] ??
                          emergencyData['description'] ??
                          'Heart attack',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

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
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildConditionCard(
                            'Type',
                            emergencyData['reason'] ??
                                emergencyData['type'] ??
                                'Cardiac',
                            'image2.gif',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildConditionCard(
                            'Breathing',
                            emergencyData['breathing'] ?? 'Normal',
                            'image4.gif',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Second row of condition cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildConditionCard(
                            'Consciousness',
                            emergencyData['consciousness'] ?? 'Normal',
                            'image3.gif',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildConditionCard(
                            'Visible Injuries',
                            emergencyData['visibleInjuries'] ??
                                'Bleeding, Fractures',
                            'image5.gif',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Location
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.split(',').first, // Take first part of address
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Location ${locationData['locationType'] ?? 'selected'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Time and date
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requested Time & date',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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

              // Incident description
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
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
                          "No description provided",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Status info
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.local_taxi,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatStatus(
                              widget.completeData['status'] ?? 'unknown'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getStatusTextColor(
                                widget.completeData['status']),
                          ),
                        ),
                      ],
                    ),
                    if (widget.completeData['status'] == 'accepted' ||
                        widget.completeData['status'] == 'completed') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Driver: $driverName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                        ],
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
                            'ETA: ${widget.completeData['estimatedArrivalTime'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Searching for ambulance';
      case 'accepted':
        return 'Ambulance on the way';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/gifimage/$imageAsset',
            width: 24,
            height: 24,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
