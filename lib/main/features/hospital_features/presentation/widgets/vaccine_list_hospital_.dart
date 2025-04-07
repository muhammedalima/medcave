import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/common/database/model/hospitalmodels/firebase_vaccine.dart';
import 'package:medcave/main/features/hospital_features/presentation/pages/vaccine_screen.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/vaccine_card_hospital.dart';

class VaccineList extends StatefulWidget {
  final String hospitalId;
  final String searchQuery;

  const VaccineList({
    Key? key,
    required this.hospitalId,
    required this.searchQuery,
  }) : super(key: key);

  @override
  State<VaccineList> createState() => _VaccineListState();
}

class _VaccineListState extends State<VaccineList> {
  late FirebaseVaccineService _firebaseService;
  late Future<Stream<QuerySnapshot>> _vaccinesStreamFuture;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseVaccineService();
    _vaccinesStreamFuture = _firebaseService.getVaccinesStream();
  }

  // Filter vaccines based on search query
  List<Map<String, dynamic>> _filterVaccines(
      List<Map<String, dynamic>> vaccines, String query) {
    if (query.isEmpty) {
      return vaccines;
    }
    final lowerQuery = query.toLowerCase();
    return vaccines.where((vaccine) {
      final vaccineName = vaccine['vaccineName']?.toString().toLowerCase() ?? '';
      final ageGroup = vaccine['ageGroup']?.toString().toLowerCase() ?? '';
      final description = vaccine['description']?.toString().toLowerCase() ?? '';
      return vaccineName.contains(lowerQuery) ||
             ageGroup.contains(lowerQuery) ||
             description.contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Stream<QuerySnapshot>>(
      future: _vaccinesStreamFuture,
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
                return const Center(child: Text('No vaccines available'));
              }

              // Convert Firestore documents to a list of vaccine maps
              final vaccines = streamSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id, // Include the document ID for potential updates/deletes
                  'vaccineName': data['name'] ?? 'Unnamed Vaccine',
                  'ageGroup': data['ageGroup'] ?? 'Unknown Age Group',
                  'available': data['available'] ?? false,
                  'description': data['description'] ?? 'No description provided',
                  'lastUpdated': data['lastUpdated'] != null
                      ? (data['lastUpdated'] as Timestamp).toDate().toString()
                      : 'Unknown',
                };
              }).toList();

              // Filter vaccines based on search query
              final filteredVaccines = _filterVaccines(vaccines, widget.searchQuery);

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85, // Adjusted for vaccine card content
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredVaccines.length,
                itemBuilder: (context, index) {
                  final vaccine = filteredVaccines[index];
                  return HospitalVaccineCard(
                    vaccineName: vaccine['vaccineName'],
                    ageGroup: vaccine['ageGroup'],
                    available: vaccine['available'],
                    onTap: () {
                      // Navigate to detail screen with the vaccine data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VaccineDetailScreen(vaccine: vaccine),
                        ),
                      );
                    },
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