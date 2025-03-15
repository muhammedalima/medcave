// lib/Users/Mobilescreens/features/personal_profile/widget/profile_header_widget.dart

import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/presentation/editprofile_patient.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onProfileUpdated;

  const ProfileHeaderWidget({
    Key? key,
    required this.userData,
    required this.onProfileUpdated,
  }) : super(key: key);

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
      child: Row(
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
            backgroundColor: Colors.blue,
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
