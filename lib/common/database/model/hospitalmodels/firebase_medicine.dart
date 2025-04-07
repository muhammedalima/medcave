import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/main/features/hospital_features/model/hospitaldata.dart';

class FirebaseMedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the current hospital ID from HospitalData
  Future<String> get _currentHospitalId async => await HospitalData.getSelectedHospitalId();

  // Add a new medicine
  Future<void> addMedicine({
    required String name,
    required String description,
    required bool isAvailable,
  }) async {
    final hospitalId = await _currentHospitalId;

    final medicineData = {
      'name': name,
      'description': description,
      'available': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('medicinedetails')
        .add(medicineData);
  }

  // Update an existing medicine
  Future<void> updateMedicine({
    required String medicineId,
    required String name,
    required String description,
    required bool isAvailable,
  }) async {
    final hospitalId = await _currentHospitalId;

    final medicineData = {
      'name': name,
      'description': description,
      'available': isAvailable,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('medicinedetails')
        .doc(medicineId)
        .update(medicineData);
  }

  // Delete a medicine
  Future<void> deleteMedicine(String medicineId) async {
    final hospitalId = await _currentHospitalId;

    await _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('medicinedetails')
        .doc(medicineId)
        .delete();
  }

  // Get stream of medicines
  Future<Stream<QuerySnapshot>> getMedicinesStream() async {
    final hospitalId = await _currentHospitalId;

    return _firestore
        .collection('HospitalData')
        .doc(hospitalId)
        .collection('medicinedetails')
        .snapshots();
  }
}