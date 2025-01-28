import 'package:flutter/material.dart';
import 'package:medcave/config/theme/theme.dart';
import 'package:medcave/main/splash_screen/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedCave',
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
