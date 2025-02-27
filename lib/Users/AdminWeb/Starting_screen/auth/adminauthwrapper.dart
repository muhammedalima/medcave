import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medcave/Users/AdminWeb/Starting_screen/auth/login/adminlogin.dart';
import 'package:medcave/Users/AdminWeb/home/presentation/adminhome.dart';

class Adminauthwrapper extends StatefulWidget {
  const Adminauthwrapper({super.key});

  @override
  State<Adminauthwrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<Adminauthwrapper> {
  late final Stream<User?> _authStream;
  bool? _hasSeenOnboarding; // Initialize as null for clarity

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const Adminhome();
        }
        return const Adminlogin();
      },
    );
  }
}
