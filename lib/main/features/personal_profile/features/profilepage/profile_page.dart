import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcave/main/features/personal_profile/features/profilepage/widget/custom_tab.dart';
import 'package:medcave/main/features/personal_profile/features/medical_history/medical_history.dart';
import 'package:medcave/main/features/personal_profile/features/medication/widget/medications_tab.dart';
import 'package:medcave/main/features/personal_profile/features/profilepage/widget/profile_header.dart';

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
  final GlobalKey _tabBarKey = GlobalKey();
  bool _isTabBarSticky = false;
  double _headerHeight = 0;
  double _tabBarHeight = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _scrollController.addListener(_updateStickyState);

    // Measure the header and tab bar heights after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeights();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateStickyState);
    _scrollController.dispose();
    super.dispose();
  }

  // Measures the header and tab bar heights
  void _measureHeights() {
    final RenderBox? headerBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? tabBarBox =
        _tabBarKey.currentContext?.findRenderObject() as RenderBox?;

    if (headerBox != null && tabBarBox != null) {
      setState(() {
        _headerHeight = headerBox.size.height;
        _tabBarHeight = tabBarBox.size.height;
      });
    }
  }

  // Updates the sticky state based on scroll position
  void _updateStickyState() {
    // Tab becomes sticky when the scroll position reaches the tab bar
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
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
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

              // Tab bar that will be part of the scrolling
              SliverPersistentHeader(
                delegate: _StickyTabBarDelegate(
                  child: Container(
                    key: _tabBarKey,
                    child: CustomTabBar(
                      selectedIndex: _selectedTabIndex,
                      onTabSelected: _handleTabSelection,
                    ),
                  ),
                  // This makes the tab bar stick to the top when it reaches there
                  minHeight: _tabBarHeight > 0 ? _tabBarHeight : 50,
                  maxHeight: _tabBarHeight > 0 ? _tabBarHeight : 50,
                ),
                pinned: true, // This is what makes it stick when scrolled
              ),
            ];
          },
          // Main content that will scroll beneath the sticky tab bar
          body: IndexedStack(
            index: _selectedTabIndex,
            children: [
              MedicationsTab(userId: userId),
              MedicalHistoryTab(userId: userId),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom delegate for the sticky tab bar
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyTabBarDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}