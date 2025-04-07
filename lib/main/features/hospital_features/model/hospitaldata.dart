import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HospitalData {
  static const String SELECTED_HOSPITAL_ID_KEY = 'selected_hospital_id';
  static const String DEFAULT_HOSPITAL_ID = "hvv3lp0JZkUYfQ6Pvp8fN6UWFFD2";
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> getHospitals() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('admins').get();
      List<Map<String, dynamic>> hospitals = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> hospital = await _mapFirestoreDocToHospital(doc);
        hospitals.add(hospital);
      }
      return hospitals;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching hospitals: $e');
      }
      return [];
    }
  }

  static Future<Map<String, dynamic>> _mapFirestoreDocToHospital(
      DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final doctorsCount = await _getDoctorsCount(doc.id);
    final labTestsCount = await _getLabTestsCount(doc.id);
    final medicinesCount = await _getMedicinesCount(doc.id);
    final specialties = await _getSpecialties(doc.id);

    return {
      "id": doc.id,
      "name": data['hospitalName'] ?? 'Unknown Hospital',
      "location": data['hospitalAddress'] ?? 'Unknown Location',
      "rating": 4.5,
      "specialties": specialties,
      "stats": {
        "Doctors": {"count": doctorsCount},
        "Lab Tests": {"count": labTestsCount},
        "Medicines": {"count": medicinesCount},
      },
      "palliativeCare": {
        "available": data['hasPalliativeCare'] ?? false,
        "description": data['palliativeCareDescription'] ?? '',
        "contactNumber": data['palliativeCareContact'] ?? '',
      },
    };
  }

  static Future<int> _getDoctorsCount(String hospitalId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('HospitalData')
          .doc(hospitalId)
          .collection('doctorsdetails')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching doctors count: $e');
      }
      return 0;
    }
  }

  static Future<int> _getLabTestsCount(String hospitalId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('HospitalData')
          .doc(hospitalId)
          .collection('labdetails')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching lab tests count: $e');
      }
      return 0;
    }
  }

  static Future<int> _getMedicinesCount(String hospitalId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('HospitalData')
          .doc(hospitalId)
          .collection('medicinedetails')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching medicines count: $e');
      }
      return 0;
    }
  }

  static Future<List<String>> _getSpecialties(String hospitalId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('HospitalData')
          .doc(hospitalId)
          .collection('doctorsdetails')
          .get();
      Set<String> specialties = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['specialization']
              ?.toString())
          .where((specialization) => specialization != null)
          .cast<String>()
          .toSet();
      return specialties.toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching specialties: $e');
      }
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchHospitals(
      String query) async {
    if (query.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> hospitals = await getHospitals();
    return hospitals
        .where((hospital) =>
            hospital["name"]
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            hospital["location"]
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList();
  }

  static Future<Map<String, dynamic>?> getHospitalById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(id).get();
      if (doc.exists) {
        return await _mapFirestoreDocToHospital(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching hospital by ID: $e');
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getHospitalByName(String name) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('admins')
          .where('hospitalName', isEqualTo: name)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return await _mapFirestoreDocToHospital(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching hospital by name: $e');
      }
      return null;
    }
  }

  static const Map<String, dynamic> defaultStats = {
    "Doctors": {"count": 0},
    "Lab Tests": {"count": 0},
    "Medicines": {"count": 0},
  };

  static const Map<String, dynamic> defaultPalliativeCare = {
    "available": false,
    "description": "",
    "contactNumber": ""
  };

  static Future<void> saveSelectedHospitalId(String hospitalId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SELECTED_HOSPITAL_ID_KEY, hospitalId);
  }

  static Future<String> getSelectedHospitalId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SELECTED_HOSPITAL_ID_KEY) ?? DEFAULT_HOSPITAL_ID;
  }
}
