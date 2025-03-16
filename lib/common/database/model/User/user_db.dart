import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

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
  // Create a stream controller to notify about profile updates
  static final _profileUpdateController = StreamController<void>.broadcast();
  
  // Stream that UI can listen to for profile updates
  static Stream<void> get profileUpdates => _profileUpdateController.stream;

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
        
        // Notify listeners that profile has been updated
        _profileUpdateController.add(null);

        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving onboarding data: $e');
      }
      return false;
    }
  }

  // Update user profile data
  static Future<bool> updateProfile(Map<String, dynamic> updatedData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Add updated timestamp
        updatedData['updatedAt'] = FieldValue.serverTimestamp();
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updatedData);
        
        // Notify listeners that profile has been updated
        _profileUpdateController.add(null);
        
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile data: $e');
      }
      return false;
    }
  }

  // Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('hasSeenOnboarding') ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking onboarding status: $e');
      }
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
        
        // Notify listeners that profile has been updated
        _profileUpdateController.add(null);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing onboarding data: $e');
      }
      return false;
    }
  }
  
  // Dispose the controller when no longer needed (call this in your app's dispose method)
  static void dispose() {
    _profileUpdateController.close();
  }
}

// Mixin that can be added to profile-related screens for automatic refresh
mixin ProfileRefreshMixin<T extends StatefulWidget> on State<T> {
  late StreamSubscription _profileSubscription;
  
  @override
  void initState() {
    super.initState();
    _profileSubscription = OnboardingService.profileUpdates.listen((_) {
      // Refresh the profile data when updates occur
      refreshProfileData();
    });
  }
  
  // This method should be implemented in classes using this mixin
  void refreshProfileData();
  
  @override
  void dispose() {
    _profileSubscription.cancel();
    super.dispose();
  }
}