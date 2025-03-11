// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/user/ambulance_status.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/user/ambulance_user_page.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/user/list_ambulancerequest.dart';
import 'package:medcave/Users/Mobilescreens/features/home_screen/widget/ShowCamerScreen.dart';
import 'package:medcave/Users/Mobilescreens/features/home_screen/widget/botton_arrow.dart';
import 'package:medcave/Users/Mobilescreens/features/home_screen/widget/buttonambulanceserach.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Map to hold the latest request data
  Map<String, dynamic>? _latestRequestData;
  bool _isLoading = true;
  String? _latestRequestId;

  @override
  void initState() {
    super.initState();
    _checkForActiveRequest();
  }

  // Check for active ambulance requests
  Future<void> _checkForActiveRequest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ambulanceRequests')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'accepted']) // Only check for active requests
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        setState(() {
          _latestRequestData = doc.data() as Map<String, dynamic>;
          _latestRequestId = doc.id;
          _isLoading = false;
        });
      } else {
        setState(() {
          _latestRequestData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for active request: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Navigate to the appropriate screen based on request status
  void _navigateToAmbulanceScreen() {
    if (_latestRequestData != null && _latestRequestId != null) {
      // If there's an active request, navigate to status page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AmbulanceStatusPage(requestId: _latestRequestId!),
        ),
      );
    } else {
      // If no active request, navigate to ambulance search page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Ambulancescreenuser(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppColor.backgroundGrey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hey, Get',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'An Ambulance',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Determine where the button should navigate based on active request
                                  Buttonarrrowicon(
                                    destination:  AmbulanceRequestList()
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _latestRequestData != null 
                                    ? 'Active request in progress'
                                    : 'Search with AI magic!',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Buttonambulancesearch(
                                onClick: _navigateToAmbulanceScreen,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Drug finder section - Now clickable
                      GestureDetector(
                        onTap: () => showCameraScreen(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Find out',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'what your drug is ?',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Buttonarrrowicon(
                                  rotateAngle: 1.6,
                                  destination: null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}