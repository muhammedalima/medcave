// lib/Users/Mobilescreens/features/personal_profile/widget/profile_header_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcave/main/Starting_Screen/auth/authwrapper.dart';
import 'package:medcave/main/features/personal_profile/features/profilepage/editprofile_patient.dart';
import 'package:medcave/config/colors/appcolor.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onProfileUpdated;

  const ProfileHeaderWidget({
    Key? key,
    required this.userData,
    required this.onProfileUpdated,
  }) : super(key: key);

  // Get a consistent color based on the user's name
  Color _getProfileColor(String name) {
    if (name.isEmpty) return Colors.blue;

    // List of pleasant colors for avatars
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    // Generate a consistent index based on the name
    int colorIndex = 0;
    for (int i = 0; i < name.length; i++) {
      colorIndex += name.codeUnitAt(i);
    }

    // Ensure the index is within the range of available colors
    return colors[colorIndex % colors.length];
  }

  // Sign out function
  Future<void> _signOut(BuildContext context) async {
    try {
      // Show confirmation dialog
      bool confirmLogout = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child:
                      const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmLogout) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to login screen and remove all previous routes
      if (context.mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Close the loading dialog if there's an error
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String name = userData?['name'] ?? 'Unknown';
    String age = userData?['age']?.toString() ?? '';
    String gender = userData?['gender'] ?? '';
    String phoneNumber = userData?['phoneNumber'] ?? '';
    String profileImageUrl = userData?['profileImageUrl'] ?? '';

    // Create info text line
    List<String> infoItems = [];
    if (age.isNotEmpty) infoItems.add('$age year old');
    if (gender.isNotEmpty) infoItems.add(gender);
    if (phoneNumber.isNotEmpty) infoItems.add(phoneNumber);
    String infoText = infoItems.join(' - ');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Top row with logout button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColor.navigationBackColor,
                child: IconButton(
                  icon: Icon(
                    Icons.logout,
                    size: 32,
                    color: Colors.red,
                  ),
                  tooltip: 'Logout',
                  onPressed: () => _signOut(context),
                ),
              ),
            ],
          ),

          // User info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info aligned to the left
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileAvatar(name, profileImageUrl),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            infoText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Edit Profile Button
                    _buildEditProfileButton(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String name, String profileImageUrl) {
    return profileImageUrl.isNotEmpty
        ? CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(profileImageUrl),
          )
        : CircleAvatar(
            radius: 40,
            backgroundColor: _getProfileColor(name),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileEdit()),
          );
          onProfileUpdated();
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: const BorderSide(color: Colors.grey),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text(
          'Edit User Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
