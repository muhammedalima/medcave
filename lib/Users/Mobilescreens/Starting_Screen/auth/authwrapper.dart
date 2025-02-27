import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/OnBoarding/screen/onboarding.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/auth/login/login_screen.dart';
import 'package:medcave/Users/Mobilescreens/bottom_navigation_bar/bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<User?> _authStream;
  bool? _hasSeenOnboarding; // Initialize as null for clarity

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    _checkOnboardingStatus(); // Call async onboarding check
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;

    // Update the state to reflect onboarding status
    setState(() {
      _hasSeenOnboarding = hasSeen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state or onboarding
        if (snapshot.connectionState == ConnectionState.waiting || _hasSeenOnboarding == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is logged in
          if (!_hasSeenOnboarding!) {
            // First-time user - Show Onboarding
            return const Onboarding();
          }
          // Returning user - Show Home Screen
          return const CustomNavigationBar();
        }

        // No user - Show Login Screen
        return const LoginScreen();
      },
    );
  }
}