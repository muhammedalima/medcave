import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/custom_tab.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/medical_history.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/medications_tab.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/profile_header.dart';

mixin ProfileRefreshMixin {
  void refreshProfileData();
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with ProfileRefreshMixin {
  int _selectedTabIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isLoading = true;
  Map<String, dynamic>? userData;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  bool _isTabBarSticky = false;
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _scrollController.addListener(_updateTabBarState);

    // Measure the header height after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeaderHeight();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateTabBarState);
    _scrollController.dispose();
    super.dispose();
  }

  // Measures the header height to know when to make the tabs sticky
  void _measureHeaderHeight() {
    final RenderBox? headerBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (headerBox != null) {
      setState(() {
        _headerHeight = headerBox.size.height;
      });
    }
  }

  // Updates the tab bar sticky state based on scroll position
  void _updateTabBarState() {
    final isTabBarSticky = _scrollController.offset >= _headerHeight;
    if (isTabBarSticky != _isTabBarSticky) {
      setState(() {
        _isTabBarSticky = isTabBarSticky;
      });
    }
  }

  @override
  void refreshProfileData() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (userId.isNotEmpty) {
        final docSnapshot =
            await _firestore.collection('users').doc(userId).get();
        if (docSnapshot.exists) {
          setState(() {
            userData = docSnapshot.data();
            isLoading = false;
          });
        } else {
          if (kDebugMode) {
            print('User data not found');
          }
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleTabSelection(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main scrollable content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header section
                SliverToBoxAdapter(
                  child: Container(
                    key: _headerKey,
                    child: ProfileHeaderWidget(
                      userData: userData,
                      onProfileUpdated: refreshProfileData,
                    ),
                  ),
                ),

                // Spacer for the tab bar when it becomes sticky
                SliverToBoxAdapter(
                  child: _isTabBarSticky
                      ? SizedBox(
                          height:
                              50) // Adjust this height to match your CustomTabBar height
                      : CustomTabBar(
                          selectedIndex: _selectedTabIndex,
                          onTabSelected: _handleTabSelection,
                        ),
                ),

                // Content based on selected tab
                SliverFillRemaining(
                  child: _selectedTabIndex == 0
                      ? MedicationsTab(userId: userId)
                      : MedicalHistoryTab(userId: userId),
                ),
              ],
            ),

            // Sticky tab bar that appears when scrolled
            if (_isTabBarSticky)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: CustomTabBar(
                    selectedIndex: _selectedTabIndex,
                    onTabSelected: _handleTabSelection,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
