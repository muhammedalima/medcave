import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/common/database/model/hospitalmodels/firebase_lab.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/lab_card_hospital.dart';

class LabTestList extends StatefulWidget {
  final String hospitalId;
  final String searchQuery;

  const LabTestList({
    Key? key,
    required this.hospitalId,
    required this.searchQuery,
  }) : super(key: key);

  @override
  State<LabTestList> createState() => _LabTestListState();
}

class _LabTestListState extends State<LabTestList> {
  late FirebaseComponentService2 _firebaseService;
  late Future<Stream<QuerySnapshot>> _labTestsStreamFuture;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseComponentService2();
    _labTestsStreamFuture = _firebaseService.getLabTestsStream();
  }

  // Filter lab tests based on search query
  List<Map<String, dynamic>> _filterLabTests(
      List<Map<String, dynamic>> labTests, String query) {
    if (query.isEmpty) {
      return labTests;
    }
    final lowerQuery = query.toLowerCase();
    return labTests.where((test) {
      final name = test['name']?.toString().toLowerCase() ?? '';
      final prerequisites = test['prerequisites']?.toString().toLowerCase() ?? '';
      return name.contains(lowerQuery) || prerequisites.contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Stream<QuerySnapshot>>(
      future: _labTestsStreamFuture,
      builder: (context, futureSnapshot) {
        // Handle loading state of the Future
        if (futureSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors from the Future
        if (futureSnapshot.hasError) {
          return Center(child: Text('Error: ${futureSnapshot.error}'));
        }

        // Once the Future resolves, use the Stream in a StreamBuilder
        if (futureSnapshot.hasData) {
          return StreamBuilder<QuerySnapshot>(
            stream: futureSnapshot.data,
            builder: (context, streamSnapshot) {
              // Handle loading state of the Stream
              if (streamSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Handle errors from the Stream
              if (streamSnapshot.hasError) {
                return Center(child: Text('Error: ${streamSnapshot.error}'));
              }

              // Handle no data
              if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No lab tests available'));
              }

              // Convert Firestore documents to a list of lab test maps
              final labTests = streamSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id, // Include the document ID for potential updates/deletes
                  'testName': data['name'] ?? 'Unnamed Test',
                  'price': '₹${data['price']?.toString() ?? '0'}',
                  'description': data['prerequisites'] ?? 'No prerequisites provided',
                  'isAvailable': data['available'] ?? false,
                  'prerequisites': data['prerequisites'] ?? '',
                  'lastUpdated': data['lastUpdated'] != null
                      ? (data['lastUpdated'] as Timestamp).toDate().toString()
                      : 'Unknown',
                };
              }).toList();

              // Filter lab tests based on search query
              final filteredLabTests = _filterLabTests(labTests, widget.searchQuery);

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredLabTests.length,
                itemBuilder: (context, index) {
                  final labTest = filteredLabTests[index];
                  return HospitalLabCard(
                    testName: labTest['testName'] ?? '',
                    price: labTest['price'] ?? '',
                    isAvailable: labTest['isAvailable'] ?? false,
                    labTestDetails: labTest,
                  );
                },
              );
            },
          );
        }

        // Fallback case (shouldn't normally occur)
        return const Center(child: Text('Unexpected error occurred'));
      },
    );
  }
}