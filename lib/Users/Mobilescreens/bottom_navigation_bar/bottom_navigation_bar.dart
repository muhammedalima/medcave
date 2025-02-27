import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:fluttericon/octicons_icons.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/ambulance_driver_page.dart';
import 'package:medcave/Users/Mobilescreens/features/home_screen/presentation/pages/home_page.dart';
import 'package:medcave/Users/Mobilescreens/features/hospital_features/presentation/pages/hospital_page.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/presentation/pages/profile_page.dart';

class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({super.key});

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    HospitalPage(),
    AmbulanceDriverPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: GNav(
            color: Colors.black,
            activeColor: AppColor.primaryGreen,
            tabBackgroundColor: AppColor.darkBlack,
            gap: 8,
            tabBorderRadius: 16,
            padding: const EdgeInsets.all(16),
            duration: const Duration(milliseconds: 1000),
            iconSize: 25,
            tabs: const [
              GButton(
                icon: Octicons.home,
                text: 'Home',
              ),
              GButton(
                icon: FontAwesome.plus_squared_alt,
                text: 'Hospital',
              ),
              GButton(
                icon: FontAwesome.ambulance,
                text: 'Ambulance',
              ),
              GButton(
                icon: Icons.person_2_outlined,
                text: 'Profile',
              ),
            ],
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
