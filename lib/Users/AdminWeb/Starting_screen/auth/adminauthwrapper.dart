import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medcave/Users/AdminWeb/Starting_screen/auth/login/adminlogin.dart';
class Adminauthwrapper extends StatefulWidget {
  const Adminauthwrapper({super.key});

  @override
  State<Adminauthwrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<Adminauthwrapper> {
  late final Stream<User?> _authStream;

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
          // return const AdminDashboard();
        }
        return const AdminLoginPage();
      },
    );
  }
}
