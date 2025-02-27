import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medcave/Users/AdminWeb/Starting_screen/splash_screen/splash_screen.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/splash_screen/splash_screen.dart';

class Userwrapper extends StatefulWidget {
  const Userwrapper({super.key});

  @override
  State<Userwrapper> createState() => _UserwrapperState();
}

class _UserwrapperState extends State<Userwrapper> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnPlatform();
  }

  void _navigateBasedOnPlatform() {
    // Add a small delay to ensure the navigation happens after the widget is built
    Future.delayed(const Duration(milliseconds: 100), () {
      if (kIsWeb) {
        // Navigate to admin splash screen for web
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminSplashScreen()),
        );
      } else if (Platform.isAndroid) {
        // Navigate to regular splash screen for Android
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
      // You can add more conditions for other platforms if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    // This is just a placeholder that will be quickly replaced
    return const Scaffold(body: SizedBox());
  }
}
