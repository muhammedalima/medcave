import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/main/features/hospital_features/model/hospitaldata.dart';

class FirebaseVaccineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the current hospital ID from HospitalData
  Future<String> get _currentHospitalId async => await HospitalData.getSelectedHospitalId();

  // Add a new vaccine
  Future<void> addVaccine({
    required String name,
    required String description,
    required String ageGroup,
    required bool isAvailable,
  }) async {
    final hospitalId = await _currentHospitalId;

    final vaccineData = {
      'name': name,
      'description': description,
      'ageGroup': ageGroup,
      'available': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('vaccinedetails')
        .add(vaccineData);
  }

  // Update an existing vaccine
  Future<void> updateVaccine({
    required String vaccineId,
    required String name,
    required String description,
    required String ageGroup,
    required bool isAvailable,
  }) async {
    final hospitalId = await _currentHospitalId;

    final vaccineData = {
      'name': name,
      'description': description,
      'ageGroup': ageGroup,
      'available': isAvailable,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('vaccinedetails')
        .doc(vaccineId)
        .update(vaccineData);
  }

  // Delete a vaccine
  Future<void> deleteVaccine(String vaccineId) async {
    final hospitalId = await _currentHospitalId;

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('vaccinedetails')
        .doc(vaccineId)
        .delete();
  }

  // Get stream of vaccines
  Future<Stream<QuerySnapshot>> getVaccinesStream() async {
    final hospitalId = await _currentHospitalId;

    return _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('vaccinedetails')
        .snapshots();
  }
}