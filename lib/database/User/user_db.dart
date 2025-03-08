import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define the OnboardingData class that was missing from the original code
class OnboardingData {
  final String? name;
  final String? phoneNumber;
  final String? driverLicense;
  final bool isAmbulanceDriver;
  final String? vehicleRegistrationNumber;
  final String? ambulanceType;
  final List<String>? equipment;
  final int? age;
  final String? gender;

  OnboardingData({
    this.name = '',
    this.phoneNumber = '',
    this.driverLicense = '',
    this.isAmbulanceDriver = false,
    this.vehicleRegistrationNumber = '',
    this.ambulanceType = '',
    this.equipment = const [],
    this.age,
    this.gender = '',
  });
}

class OnboardingService {
  // Save onboarding data to Firestore
  static Future<bool> saveOnboardingData(
    OnboardingData data,
    String selectedAmbulanceType,
    List<String> selectedEquipment,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create a map with only the data we need based on user type
        Map<String, dynamic> userData = {
          'name': data.name,
          'phoneNumber': data.phoneNumber,
          'isAmbulanceDriver': data.isAmbulanceDriver,
          'isAdmin': false, // Adding isAdmin field as requested
          'age': data.age,
          'gender': data.gender,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add driver-specific data only if user is an ambulance driver
        if (data.isAmbulanceDriver) {
          userData.addAll({
            'driverLicense': data.driverLicense,
            'vehicleRegistrationNumber': data.vehicleRegistrationNumber,
            'ambulanceType': selectedAmbulanceType,
            'equipment': selectedEquipment,
          });
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
              userData,
              SetOptions(merge: true),
            );

        // Store onboarding completion flag in shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);

        return true;
      }
      return false;
    } catch (e) {
      print('Error saving onboarding data: $e');
      return false;
    }
  }

  // Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('hasSeenOnboarding') ?? false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }
  
  // Clear onboarding data - useful for testing and reset functionality
  static Future<bool> clearOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', false);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // We'll just reset the onboarding flag in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'hasCompletedOnboarding': false,
        });
      }
      return true;
    } catch (e) {
      print('Error clearing onboarding data: $e');
      return false;
    }
  }
}