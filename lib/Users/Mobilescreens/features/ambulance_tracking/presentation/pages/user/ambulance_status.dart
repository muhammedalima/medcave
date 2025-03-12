import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/Users/Mobilescreens/bottom_navigation_bar/bottom_navigation_bar.dart';
import 'package:medcave/Users/Mobilescreens/commonWidget/customnavbar.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/user/details_ambulanceuser.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AmbulanceStatusPage extends StatefulWidget {
  final String requestId;
  const AmbulanceStatusPage({
    super.key,
    required this.requestId,
  });

  @override
  State<AmbulanceStatusPage> createState() => _AmbulanceStatusPageState();
}

class _AmbulanceStatusPageState extends State<AmbulanceStatusPage> {
  int currentStep = 0;
  bool isLoading = true;
  Map<String, dynamic>? requestData;
  late StreamSubscription<DocumentSnapshot> _requestSubscription;

  @override
  void initState() {
    super.initState();
    _setupRequestListener();
  }

  void _setupRequestListener() {
    final requestRef = FirebaseFirestore.instance
        .collection('ambulanceRequests')
        .doc(widget.requestId);

    _requestSubscription = requestRef.snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        // Check if there's an assignedDriverId and fetch driver details if needed
        if (data['assignedDriverId'] != null &&
            data['assignedDriverId'].isNotEmpty &&
            (data['driverPhoneNumber'] == null || data['driverName'] == null)) {
          try {
            // Fetch driver details from users collection
            final driverDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(data['assignedDriverId'])
                .get();

            if (driverDoc.exists) {
              final driverData = driverDoc.data() as Map<String, dynamic>;
              // Update the request data with driver details
              data['driverName'] = driverData['name'] ?? 'Unknown';
              data['driverPhoneNumber'] =
                  driverData['phoneNumber'] ?? 'Unknown';

              // Update the Firestore document to cache these values
              await requestRef.update({
                'driverName': data['driverName'],
                'driverPhoneNumber': data['driverPhoneNumber'],
              });
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching driver details: $e');
            }
          }
        }

        setState(() {
          requestData = data;
          isLoading = false;
          _updateCurrentStep();
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request not found')),
        );
      }
    }, onError: (error) {
      setState(() {
        isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading request: $error')),
      );
    });
  }

  void _updateCurrentStep() {
    if (requestData != null) {
      String status = requestData!['status'];
      switch (status) {
        case 'pending':
          currentStep = 0;
          break;
        case 'accepted':
          currentStep = 1;
          break;
        case 'completed':
          currentStep = 2;
          break;
        case 'cancelled':
          // Handle cancelled state
          break;
      }
    }
  }

  @override
  void dispose() {
    _requestSubscription.cancel();
    super.dispose();
  }

  Widget _buildLoadingIcon() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  void _showAmbulanceRequestPopup() {
    if (requestData == null) {
      return;
    }

    String driverName = requestData!['driverName'] ?? 'Unknown';
    String estimatedTime = requestData!['estimatedArrivalTime'] ?? 'Unknown';
    String phoneNumber = requestData!['driverPhoneNumber'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Your request has been selected by $driverName",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Will Arrive In $estimatedTime",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // Implement call functionality
                          _makePhoneCall(phoneNumber);
                        },
                        child: Text(
                          "Call - $phoneNumber",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () {
                          // Implement copy functionality
                          Clipboard.setData(ClipboardData(text: phoneNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Phone number copied to clipboard')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  void _navigateToUserAmbulanceScreen() {
    if (requestData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserAmbulanceDetailScreen(
            completeData: requestData!,
            requestId: widget.requestId,
          ),
        ),
      );
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

    if (requestData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Failed to load request data"),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    // Extract data for display
    String status = requestData!['status'];
    String driverName = requestData!['driverName'] ?? 'Ambulance';
    String estimatedTime =
        requestData!['estimatedArrivalTime'] ?? 'Unknown time';
    bool isAccepted = status == 'accepted';
    bool isCompleted = status == 'completed';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        icon: Icons.arrow_back,
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const CustomNavigationBar()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        },
        rightIcon: Icons.info_outline,
        onRightPressed: _navigateToUserAmbulanceScreen,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Heart Icon
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 30,
                child: Icon(
                  Icons.favorite_border,
                  color: isCompleted ? Colors.red : Colors.grey,
                  size: 30,
                ),
              ),

              const SizedBox(height: 20),

              // Status Text
              Text(
                status == 'pending'
                    ? 'Looking for ambulance...'
                    : status == 'accepted'
                        ? 'Ambulance is on the way!'
                        : status == 'completed'
                            ? 'Ambulance Arrived'
                            : 'Request Status',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Subtitle
              Text(
                status == 'pending'
                    ? 'There are ambulances around you'
                    : status == 'accepted'
                        ? 'Expected arrival in $estimatedTime'
                        : status == 'completed'
                            ? 'Take Care and Stay Safe'
                            : 'Request Status',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Status Steps
              _buildStatusStep(
                'Search for ambulance',
                true,
                const Icon(Icons.check, color: Colors.white),
              ),

              _buildStatusStep(
                'Picked by an ambulance',
                isAccepted || isCompleted,
                status == 'pending'
                    ? _buildLoadingIcon()
                    : isAccepted || isCompleted
                        ? const Icon(Icons.check, color: Colors.white)
                        : const Icon(Icons.close, color: Colors.white),
              ),

              if (isAccepted || isCompleted)
                GestureDetector(
                  onTap: _showAmbulanceRequestPopup,
                  child: Container(
                    margin:
                        const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Request accepted by\n$driverName',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              _buildStatusStep(
                'Ambulance reached',
                isCompleted,
                isAccepted && !isCompleted
                    ? _buildLoadingIcon()
                    : isCompleted
                        ? const Icon(Icons.check, color: Colors.white)
                        : const Icon(Icons.close, color: Colors.white),
              ),

              if (isCompleted)
                Container(
                  margin: const EdgeInsets.only(left: 20, top: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Ambulance has reached your location',
                    textAlign: TextAlign.center,
                  ),
                ),

              const Spacer(),

              // Cancel button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStep(String title, bool completed, Widget icon) {
    return Container(
      margin: const EdgeInsets.only(left: 20, top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: completed ? Colors.black : Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon,
          ),
        ],
      ),
    );
  }
}
