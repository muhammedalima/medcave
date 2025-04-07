import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/common/database/model/hospitalmodels/firebase_doctor.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/doctors_card_hospital.dart';

class DoctorList extends StatefulWidget {
  final String hospitalId;
  final String searchQuery;

  const DoctorList({
    Key? key,
    required this.hospitalId,
    required this.searchQuery,
  }) : super(key: key);

  @override
  State<DoctorList> createState() => _DoctorListState();
}

class _DoctorListState extends State<DoctorList> {
  late final FirebaseComponentService _firebaseService;
  late Future<Stream<QuerySnapshot>> _doctorsStreamFuture;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseComponentService();
    _doctorsStreamFuture = _firebaseService.getDoctorsStream();
  }

  // Filter doctors based on search query
  List<Map<String, dynamic>> _filterDoctors(
      List<Map<String, dynamic>> doctors, String query) {
    if (query.isEmpty) {
      return doctors;
    }
    final lowerQuery = query.toLowerCase();
    return doctors.where((doctor) {
      final fullName =
          '${doctor['firstName']} ${doctor['lastName']}'.toLowerCase();
      final specialization =
          doctor['specialization']?.toString().toLowerCase() ?? '';
      return fullName.contains(lowerQuery) || specialization.contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Stream<QuerySnapshot>>(
      future: _doctorsStreamFuture,
      builder: (context, futureSnapshot) {
        // Handle loading state of the Future
        if (futureSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
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
                return Center(child: CircularProgressIndicator());
              }

              // Handle errors from the Stream
              if (streamSnapshot.hasError) {
                return Center(child: Text('Error: ${streamSnapshot.error}'));
              }

              // Handle no data
              if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
                return Center(child: Text('No doctors found for this hospital'));
              }

              // Map Firestore data to a list of doctor maps
              final doctors = streamSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'firstName': data['firstName'] ?? '',
                  'lastName': data['lastName'] ?? '',
                  'specialization': data['specialization'] ?? '',
                  'isAvailableToday': data['available'] ?? false,
                  'availableSlots': data['timeslots'] ?? <String>[],
                  'lastUpdated': (data['lastUpdated'] as Timestamp?)
                          ?.toDate()
                          .toString() ??
                      '',
                  'qualification': 'N/A', // Not in Firestore, add if needed
                  'yearsOfExperience': data['experience'] ?? 0,
                };
              }).toList();

              // Filter doctors based on search query
              final filteredDoctors = _filterDoctors(doctors, widget.searchQuery);

              // Build the list
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredDoctors.length,
                itemBuilder: (context, index) {
                  final doctor = filteredDoctors[index];
                  return DoctorCard(
                    firstName: doctor['firstName'],
                    lastName: doctor['lastName'],
                    specialization: doctor['specialization'],
                    isAvailableToday: doctor['isAvailableToday'],
                    availableSlots: List<String>.from(doctor['availableSlots']),
                    lastUpdated: doctor['lastUpdated'],
                    qualification: doctor['qualification'],
                    yearsOfExperience: doctor['yearsOfExperience'],
                  );
                },
              );
            },
          );
        }

        // Fallback case (shouldn't normally occur)
        return Center(child: Text('Unexpected error occurred'));
      },
    );
  }
}