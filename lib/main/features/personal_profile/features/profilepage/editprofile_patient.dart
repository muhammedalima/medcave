// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/main/Starting_Screen/OnBoarding/widget/formlabel.dart';
import 'package:medcave/main/Starting_Screen/OnBoarding/widget/onboardinginput.dart';
import 'package:medcave/main/commonWidget/customnavbar.dart';
import 'package:medcave/common/database/model/User/user_db.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // User data fields
  String _name = '';
  String _phoneNumber = '';
  int? _age;
  String _gender = '';
  bool _isAmbulanceDriver = false;

  // Gender options
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Load user data from Firestore
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          final data = userData.data();
          setState(() {
            _name = data?['name'] ?? '';
            _phoneNumber = data?['phoneNumber'] ?? '';
            _age = data?['age'];
            _gender = data?['gender'] ?? '';
            _isAmbulanceDriver = data?['isAmbulanceDriver'] ?? false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a map with updated data
      Map<String, dynamic> userData = {
        'name': _name,
        'phoneNumber': _phoneNumber,
        'age': _age,
        'gender': _gender,
        'isAmbulanceDriver': _isAmbulanceDriver,
      };

      // Use the service to update the profile
      bool success = await OnboardingService.updateProfile(userData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );

        // Return with result to force profile page refresh
        Navigator.pop(context, true);
      } else {
        throw Exception("Failed to update profile");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _discardChanges() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Discard Changes'),
          content: Text('Are you sure you want to discard all changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Discard'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    FormLabelText(text: "Full Name"),
                    SizedBox(height: 8),
                    InputFieldContainer(
                      child: TextFormField(
                        initialValue: _name,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter your full name',
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _name = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Phone Number Field
                    FormLabelText(text: "Phone Number"),
                    SizedBox(height: 8),
                    InputFieldContainer(
                      child: TextFormField(
                        initialValue: _phoneNumber,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter your phone number',
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _phoneNumber = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Age Field
                    FormLabelText(text: "Age"),
                    SizedBox(height: 8),
                    InputFieldContainer(
                      child: TextFormField(
                        initialValue: _age?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter your age',
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your age';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid age';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _age = int.tryParse(value);
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Gender Field (Dropdown)
                    FormLabelText(text: "Gender"),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonFormField<String>(
                        value: _gender.isNotEmpty ? _gender : null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Select Gender',
                        ),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down),
                        items: _genderOptions.map((gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _gender = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 24),

                    // Save and Discard Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _discardChanges,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.red[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Discard',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Save Changes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
