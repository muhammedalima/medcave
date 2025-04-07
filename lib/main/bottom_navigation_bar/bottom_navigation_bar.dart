import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:fluttericon/octicons_icons.dart';
import 'package:fluttericon/rpg_awesome_icons.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:medcave/main/features/ambulance_tracking/presentation/pages/driver/driverwrapper.dart';
import 'package:medcave/main/features/hospital_features/presentation/pages/hospital_page.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/main/features/home_screen/presentation/pages/home_page.dart';
import 'package:medcave/main/features/personal_profile/features/profilepage/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({super.key});

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  int _selectedIndex = 0;
  bool _isAmbulanceDriver = false;
  bool _isLoading = true;

  late List<Widget> _widgetOptions;
  late List<GButton> _navButtons;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          final bool isAmbulanceDriver =
              userData.data()?['isAmbulanceDriver'] ?? false;

          setState(() {
            _isAmbulanceDriver = isAmbulanceDriver;
            _isLoading = false;
            _initializeWidgets();
          });
        } else {
          setState(() {
            _isAmbulanceDriver = false;
            _isLoading = false;
            _initializeWidgets();
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching user role: $e');
        }
        setState(() {
          _isAmbulanceDriver = false;
          _isLoading = false;
          _initializeWidgets();
        });
      }
    } else {
      setState(() {
        _isAmbulanceDriver = false;
        _isLoading = false;
        _initializeWidgets();
      });
    }
  }

  void _initializeWidgets() {
    // Initialize widget options based on user role
    if (_isAmbulanceDriver) {
      _widgetOptions = <Widget>[
        const HomePage(),
        HospitalPage(),
        const AmbulanceDriverWrapper(),
        const ProfilePage(),
      ];

      _navButtons = const [
        GButton(
          icon: Octicons.home,
          text: 'Home',
        ),
        GButton(
          icon: RpgAwesome.hospital_cross,
          text: 'Hospitals',
        ),
        GButton(
          icon: FontAwesome.ambulance,
          text: 'Ambulance',
        ),
        GButton(
          icon: Icons.person_2_outlined,
          text: 'Profile',
        ),
      ];
    } else {
      // Non-ambulance driver - hide ambulance tab
      _widgetOptions = <Widget>[
        const HomePage(),
        HospitalPage(),
        const ProfilePage(),
      ];

      _navButtons = const [
        GButton(
          icon: Octicons.home,
          text: 'Home',
        ),
        GButton(
          icon: RpgAwesome.hospital_cross,
          text: 'Hospitals',
        ),
        GButton(
          icon: Icons.person_2_outlined,
          text: 'Profile',
        ),
      ];
    }

    // Reset selected index if needed
    if (_selectedIndex >= _widgetOptions.length) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: GNav(
            color: AppColor.darkBlack,
            activeColor: AppColor.primaryGreen,
            tabBackgroundColor: AppColor.darkBlack,
            gap: 8,
            tabBorderRadius: 16,
            padding: const EdgeInsets.all(16),
            duration: const Duration(milliseconds: 1000),
            iconSize: 25,
            tabs: _navButtons,
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
