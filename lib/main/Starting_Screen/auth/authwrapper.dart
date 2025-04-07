import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medcave/main/Starting_Screen/OnBoarding/screen/onboarding.dart';
import 'package:medcave/main/Starting_Screen/auth/login/login_screen.dart';
import 'package:medcave/main/bottom_navigation_bar/bottom_navigation_bar.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  // Check if user data exists in Firestore
  Future<bool> _userDataExists(String userId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('Error checking user data: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If we have a logged-in user
        if (snapshot.hasData) {
          // Check if user data exists in Firestore
          return FutureBuilder<bool>(
            future: _userDataExists(snapshot.data!.uid),
            builder: (context, userDataSnapshot) {
              // Show loading while checking Firestore
              if (userDataSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If user data exists in Firestore, go to home
              if (userDataSnapshot.data == true) {
                return const CustomNavigationBar();
              } else {
                // No user data, show onboarding
                return const Onboarding();
              }
            },
          );
        }

        // No authenticated user - Show Login Screen
        return const LoginScreen();
      },
    );
  }
}