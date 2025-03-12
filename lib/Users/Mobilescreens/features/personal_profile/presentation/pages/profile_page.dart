import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/presentation/editprofile_patient.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/medical_history.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/medications_tab.dart';


mixin ProfileRefreshMixin {
  void refreshProfileData();
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin, ProfileRefreshMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isLoading = true;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void refreshProfileData() {
    // This is called whenever profile is updated elsewhere
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      if (userId.isNotEmpty) {
        final docSnapshot = await _firestore.collection('users').doc(userId).get();
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile Picture and Basic Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(
                                'https://via.placeholder.com/80',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userData?['name'] ?? 'Nandana',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${userData?['age'] ?? '21'} year old - ${userData?['gender'] ?? 'female'} - ${userData?['phoneNumber'] ?? '+912345678932'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Edit Profile Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                           Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ProfileEdit()),
    );
  

                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('Edit User Profile'),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tabs for Medications and Medical History
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Medications'),
                  Tab(text: 'Medical-History'),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.black,
              ),
              
              // Tab Content
              SizedBox(
                height: 600, // Fixed height for tab content
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Medications Tab
                    MedicationsTab(userId: userId),
                    
                    // Medical History Tab
                    MedicalHistoryTab(userId: userId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}