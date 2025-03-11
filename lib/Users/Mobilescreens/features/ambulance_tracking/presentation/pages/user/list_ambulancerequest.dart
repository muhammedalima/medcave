// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medcave/Users/Mobilescreens/bottom_navigation_bar/bottom_navigation_bar.dart';
import 'package:medcave/Users/Mobilescreens/commonWidget/customnavbar.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/user/details_ambulanceuser.dart';
import 'package:medcave/common/database/Ambulancerequest/ambulance_request_db.dart';

class AmbulanceRequestList extends StatefulWidget {
  const AmbulanceRequestList({super.key});

  @override
  State<AmbulanceRequestList> createState() => _AmbulanceRequestListState();
}

class _AmbulanceRequestListState extends State<AmbulanceRequestList> {
  final AmbulanceRequestDatabase _requestDatabase = AmbulanceRequestDatabase();
  bool _showAllRequests = false;
  final int _defaultLimit = 5;

  @override
  Widget build(BuildContext context) {
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
          }),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 16,
            ),
            // Past Rides header and view all button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Past Rides',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAllRequests = !_showAllRequests;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _showAllRequests ? 'show less' : 'view all',
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Rides list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _requestDatabase.getUserRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No past rides'));
                  }

                  final requests = snapshot.data!.docs;
                  // Limit the number of items based on _showAllRequests flag
                  final displayedRequests = _showAllRequests
                      ? requests
                      : requests.length > _defaultLimit
                          ? requests.sublist(0, _defaultLimit)
                          : requests;

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: displayedRequests.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final request = displayedRequests[index].data()
                          as Map<String, dynamic>;
                      final emergency =
                          request['emergency'] as Map<String, dynamic>?;
                      final emergencyType = emergency?['detailedReason'] ??
                          'Heart Attack'; // Default as in image

                      // Format the timestamp
                      String formattedDate = ''; // Default as in image
                      String formattedTime = ''; // Default as in image

                      if (request['timestamp'] != null) {
                        final timestamp = request['timestamp'] as Timestamp;
                        final dateTime = timestamp.toDate();
                        formattedDate =
                            '${dateTime.day} ${_getMonthAbbreviation(dateTime.month)}';
                        formattedTime = DateFormat('h:mma').format(dateTime);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          title: Text(
                            emergencyType,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  ' · ',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () async {
                            try {
                              final requestId = displayedRequests[index].id;
                              final completeData =
                                  await _requestDatabase.getRequest(requestId);

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserAmbulanceDetailScreen(
                                      requestId: requestId,
                                      completeData: completeData,
                                    ),
                                  ));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Error loading request details: $e')),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom decorative elements
            Center(
              child: SizedBox(
                width: 100,
                child: CustomPaint(
                  painter: WavyLinePainter(),
                  size: const Size(100, 20),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // "Your Health, Our Care" text in white with dark background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              color: Colors.grey[100],
              child: const Center(
                child: Text(
                  'Your Health,\nOur Care',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bottom wavy line
            Center(
              child: SizedBox(
                width: 100,
                child: CustomPaint(
                  painter: WavyLinePainter(),
                  size: const Size(100, 20),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = [
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
}

// Custom painter for the wavy line
class WavyLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(0, size.height / 2);

    final waveWidth = size.width / 4;
    for (int i = 0; i < 4; i++) {
      path.quadraticBezierTo(
        waveWidth * (i + 0.5),
        i % 2 == 0 ? 0 : size.height,
        waveWidth * (i + 1),
        size.height / 2,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
