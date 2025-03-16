import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/Users/Mobilescreens/commonWidget/quotewidget.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/details_ambulancedriver.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/widget/driver_profile.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/widget/sliderwidget.dart';
import 'package:medcave/common/database/service/AmbulanceRequestService%20.dart';
import 'package:medcave/config/colors/appcolor.dart';

class AmbulanceDriverScreen extends StatefulWidget {
  const AmbulanceDriverScreen({Key? key}) : super(key: key);

  @override
  State<AmbulanceDriverScreen> createState() => _AmbulanceDriverScreenState();
}

class _AmbulanceDriverScreenState extends State<AmbulanceDriverScreen> {
  bool isDriverActive = false;
  final String driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  Stream<DocumentSnapshot>? _driverStream;

  // Create instance of the service
  final AmbulanceRequestService _requestService = AmbulanceRequestService();

  // Lists to store the actual request data
  List<Map<String, dynamic>> currentRequests = [];
  List<Map<String, dynamic>> pastRides = [];

  @override
  void initState() {
    super.initState();
    debugPrint(
        'InitState called, driverId: ${driverId.isEmpty ? 'empty' : 'not empty'}');

    // Add a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && isLoading) {
        debugPrint('Loading timeout reached, forcing state update');
        setState(() {
          isLoading = false;
        });
      }
    });

    if (driverId.isNotEmpty) {
      _setupDriverListener();
      _loadRequestData(); // Load the request data
    } else {
      debugPrint('Driver ID empty, setting isLoading to false');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Method to load request data
  Future<void> _loadRequestData() async {
    try {
      // Fetch current requests
      final currentRequestsData = await _requestService.getCurrentRequests();

      // Fetch past rides
      final pastRidesData = await _requestService.getPastRides();

      if (mounted) {
        setState(() {
          currentRequests = currentRequestsData;
          pastRides = pastRidesData;
        });
      }
    } catch (e) {
      debugPrint('Error loading request data: $e');
    }
  }

  void _setupDriverListener() {
    // Create a stream to listen to driver document changes
    _driverStream = _firestore.collection('drivers').doc(driverId).snapshots();

    _driverStream?.listen((snapshot) {
      if (snapshot.exists) {
        final driverData = snapshot.data() as Map<String, dynamic>?;
        if (driverData != null && mounted) {
          final bool active = driverData['isDriverActive'] ?? false;
          debugPrint('Driver status from Firestore: $active');
          setState(() {
            isDriverActive = active;
            isLoading = false;
          });
        }
      } else {
        debugPrint('Driver does not exist in database, creating entry');
        _createDriverEntry().then((_) {
          if (mounted) {
            setState(() {
              isDriverActive = false;
              isLoading = false;
            });
          }
        });
      }
    }, onError: (error) {
      debugPrint('Error listening to driver data: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  Future<void> _createDriverEntry() async {
    try {
      await _firestore.collection('drivers').doc(driverId).set({
        'driverId': driverId,
        'userId': driverId,
        'isDriverActive': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Driver entry created successfully');
    } catch (e) {
      debugPrint('Error creating driver entry: $e');
    }
  }

  // Navigate to detail screen
  void _navigateToDetailScreen(Map<String, dynamic> request, bool isPastRide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AmbulanceDetailDriver(
          completeData: request['completeData'],
          requestId: request['id'],
          isPastRide: isPastRide,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'Build called, isLoading: $isLoading, isDriverActive: $isDriverActive');
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        // Replace NestedScrollView with a simpler structure
        child: Column(
          children: [
            // Profile section
            const AmbulanceDriverProfile(),

            // Slider
            AmbulanceSlider(
              driverId: driverId,
              initialValue: isDriverActive,
              onSlideComplete: (isActive) {
                // We don't need to update the state here
                // as it will be updated through the stream listener
                final message = isActive
                    ? 'You are now available for rides'
                    : 'You are now offline';

                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(message)));
              },
            ),

            // Main content in a scrollable area
            Expanded(
              child: SingleChildScrollView(
                child: isDriverActive
                    ? _buildActiveDriverContent()
                    : _buildInactiveDriverContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDriverContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Current requests list
          if (currentRequests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'No current requests',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...currentRequests
                .map((request) => _buildRequestCard(request, false)),

          const SizedBox(height: 20),

          // Past rides header with view all button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Past Rides',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 30),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('view all'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Past rides list
          if (pastRides.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'No past rides',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...pastRides.map((ride) => _buildPastRideItem(ride)),

          // Footer with tagline
          const SizedBox(height: 30),
          const Center(
              child: WaveyMessage(message: 'Your Health \nOur Priority')),
        ],
      ),
    );
  }

  Widget _buildInactiveDriverContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only show past rides when inactive
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Past Rides',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 30),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('view all'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Past rides list
          if (pastRides.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'No past rides',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...pastRides.map((ride) => _buildPastRideItem(ride)),

          // Footer with tagline
          const SizedBox(height: 30),
          const Center(
              child: WaveyMessage(
            message: 'Your Health \n Our Priority',
          )),
        ],
      ),
    );
  }

  // Modified to make the card tappable
  Widget _buildRequestCard(Map<String, dynamic> request, bool isPastRide) {
    return GestureDetector(
      onTap: () => _navigateToDetailScreen(request, isPastRide),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.primaryBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request['destination'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${request['date']} · ${request['time']} - ${request['reason']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modified to make past ride item tappable
  Widget _buildPastRideItem(Map<String, dynamic> ride) {
    return GestureDetector(
      onTap: () => _navigateToDetailScreen(ride, true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride['destination'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ride['date']} · ${ride['time']} - ${ride['reason']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
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

  @override
  void dispose() {
    _driverStream?.listen(null).cancel();
    super.dispose();
  }
}
