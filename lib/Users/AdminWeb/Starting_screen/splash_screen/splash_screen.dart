import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/Users/AdminWeb/Starting_screen/auth/adminauthwrapper.dart';

class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
        const Duration(seconds: 2),
        () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const Adminauthwrapper()//SignUpPage() ,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SvgPicture.asset(
              'assets/vectors/logo.svg',
            ).animate().fadeIn(curve: Curves.easeIn),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MED',
                  style: TextStyle(
                    fontFamily: 'Gotham',
                    fontSize: 56,
                    color: Colors.black,
                    height: 0.56,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    Text(
                      'cav',
                      style: TextStyle(
                          fontFamily: 'Gotham',
                          fontSize: 56,
                          height: 0.56,
                          color: Colors.black),
                    ),
                    Text(
                      'e',
                      style: TextStyle(
                        fontFamily: 'Gotham',
                        fontSize: 56,
                        height: 0.56,
                        color: AppColor.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .slide(
                  curve: Curves.easeOut,
                  begin: const Offset(-0.5, 0),
                )
          ],
        ),
      ),
    );
  }
}