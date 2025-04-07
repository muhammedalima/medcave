import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/main/features/hospital_features/model/hospitaldata.dart';

class FirebaseComponentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the current hospital ID from HospitalData
  Future<String> get _currentHospitalId async => await HospitalData.getSelectedHospitalId();

  // Add a new doctor
  Future<void> addDoctor({
    required String firstName,
    required String lastName,
    required String specialization,
    required int experience,
    required List<String> timeslots,
    required bool isAvailable,
  }) async {
    final hospitalId = await _currentHospitalId;

    final doctorData = {
      'firstName': firstName,
      'lastName': lastName,
      'specialization': specialization,
      'experience': experience,
      'timeslots': timeslots,
      'available': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('doctorsdetails')
        .add(doctorData);
  }

  // Update an existing doctor
  Future<void> updateDoctor({
    required String doctorId,
    required String firstName,
    required String lastName,
    required String specialization,
    required int experience,
    required List<String> timeslots,
    required bool isAvailable,
  }) async {
    final hospitalId = await _currentHospitalId;

    final doctorData = {
      'firstName': firstName,
      'lastName': lastName,
      'specialization': specialization,
      'experience': experience,
      'timeslots': timeslots,
      'available': isAvailable,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('doctorsdetails')
        .doc(doctorId)
        .update(doctorData);
  }

  // Delete a doctor
  Future<void> deleteDoctor(String doctorId) async {
    final hospitalId = await _currentHospitalId;

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('doctorsdetails')
        .doc(doctorId)
        .delete();
  }

  // Get stream of doctors
  Future<Stream<QuerySnapshot>> getDoctorsStream() async {
    final hospitalId = await _currentHospitalId;

    return _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('doctorsdetails')
        .snapshots();
  }
}