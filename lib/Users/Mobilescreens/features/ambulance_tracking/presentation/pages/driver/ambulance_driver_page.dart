import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/details_ambulancedriver.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/widget/driver_profile.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/widget/sliderwidget.dart';

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
        // Make entire screen scrollable with SingleChildScrollView
        child: SingleChildScrollView(
          child: Column(
            children: [
              AmbulanceDriverProfile(),
              // Slider at the top with Firebase integration
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

              // Content based on driver active status
              if (isDriverActive)
                _buildActiveDriverContent()
              else
                _buildInactiveDriverContent(),
            ],
          ),
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
            child: Text(
              'Your Health, Our Care',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
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
            child: Text(
              'Your Health, Our Care',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
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
          color: const Color(0xFFEDD072),
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
    super.dispose();
  }
}
