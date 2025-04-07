import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/main/features/hospital_features/model/hospitaldata.dart';

class FirebaseComponentService2 {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the current hospital ID from HospitalData
  Future<String> get _currentHospitalId async => await HospitalData.getSelectedHospitalId();

  // Add a new lab test
  Future<void> addLabTest({
    required String name,
    required double price,
    required String prerequisites,
    required bool isAvailable,
  }) async {
    final hospitalId = await _currentHospitalId;

    final labTestData = {
      'name': name,
      'price': price,
      'prerequisites': prerequisites,
      'available': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('labdetails')
        .add(labTestData);
  }

  // Update an existing lab test
  Future<void> updateLabTest({
    required String labTestId,
    required String name,
    required double price,
    required String prerequisites,
    required bool isAvailable,
  }) async {
    final hospitalId = await _currentHospitalId;

    final labTestData = {
      'name': name,
      'price': price,
      'prerequisites': prerequisites,
      'available': isAvailable,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('labdetails')
        .doc(labTestId)
        .update(labTestData);
  }

  // Delete a lab test
  Future<void> deleteLabTest(String labTestId) async {
    final hospitalId = await _currentHospitalId;

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('labdetails')
        .doc(labTestId)
        .delete();
  }

  // Get stream of lab tests
  Future<Stream<QuerySnapshot>> getLabTestsStream() async {
    final hospitalId = await _currentHospitalId;

    return _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('labdetails')
        .snapshots();
  }
}