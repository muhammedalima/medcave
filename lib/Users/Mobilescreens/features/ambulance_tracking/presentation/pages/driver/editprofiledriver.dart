// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/OnBoarding/widget/formlabel.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/OnBoarding/widget/onboardinginput.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/OnBoarding/widget/selectableButtton.dart';
import 'package:medcave/Users/Mobilescreens/commonWidget/customnavbar.dart';
import 'package:medcave/common/database/model/User/driver_db.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverProfileEdit extends StatefulWidget {
  const DriverProfileEdit({super.key});

  @override
  State<DriverProfileEdit> createState() => _DriverProfileEditState();
}

class _DriverProfileEditState extends State<DriverProfileEdit> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Driver data fields
  String _driverLicense = '';
  String _vehicleRegistrationNumber = '';
  String _selectedAmbulanceType = '';
  List<String> _selectedEquipment = [];

  // Ambulance type options
  final List<Map<String, String>> _ambulanceTypes = [
    {
      'value': 'BLS',
      'title': 'Basic Life Support',
      'subtitle': 'Essential medical equipment and trained staff'
    },
    {
      'value': 'ALS',
      'title': 'Advanced Life Support',
      'subtitle': 'Advanced medical equipment and specialized staff'
    },
    {
      'value': 'PTV',
      'title': 'Patient Transport Vehicle',
      'subtitle': 'Basic medical support for non-emergency transport'
    },
    {
      'value': 'NEONATAL',
      'title': 'Neonatal Ambulance',
      'subtitle': 'Specialized equipment for newborn care'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load driver data
      final driverData = await DriverDatabase.getCurrentDriverData();

      if (driverData != null) {
        setState(() {
          _driverLicense = driverData['driverLicense'] ?? '';
          _vehicleRegistrationNumber =
              driverData['vehicleRegistrationNumber'] ?? '';
          _selectedAmbulanceType = driverData['ambulanceType'] ?? '';
          _selectedEquipment = List<String>.from(driverData['equipment'] ?? []);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading driver data: $e')),
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
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Update driver data
        DriverData driverData = DriverData(
          driverId: user.uid,
          userId: user.uid,
          driverLicense: _driverLicense,
          vehicleRegistrationNumber: _vehicleRegistrationNumber,
          ambulanceType: _selectedAmbulanceType,
          equipment: _selectedEquipment,
          isDriverActive: true,
        );

        bool success = await DriverDatabase.saveDriverData(driverData);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Driver profile updated successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update driver profile')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating driver profile: $e')),
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

  // Get the subtitle for the currently selected ambulance type
  String get _selectedAmbulanceTypeSubtitle {
    final type = _ambulanceTypes.firstWhere(
      (type) => type['value'] == _selectedAmbulanceType,
      orElse: () => {'value': '', 'title': '', 'subtitle': ''},
    );
    return type['subtitle'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    // Driver License Section
                    FormLabelText(text: "Driver License Number"),
                    SizedBox(height: 8),
                    InputFieldContainer(
                      child: TextFormField(
                        initialValue: _driverLicense,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'KL 49000 5000',
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your license number';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _driverLicense = value.toUpperCase();
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    FormLabelText(text: "Vehicle Registration Number"),
                    SizedBox(height: 8),
                    InputFieldContainer(
                      child: TextFormField(
                        initialValue: _vehicleRegistrationNumber,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'KL 01 AB 1234',
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter vehicle registration number';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _vehicleRegistrationNumber = value.toUpperCase();
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 24),

                    // Ambulance Type Section (Dropdown)
                    FormLabelText(text: "Ambulance Type"),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonFormField<String>(
                        value: _selectedAmbulanceType.isNotEmpty
                            ? _selectedAmbulanceType
                            : null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Select Ambulance Type',
                        ),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an ambulance type';
                          }
                          return null;
                        },
                        items: _ambulanceTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type['value'],
                            child: Text(type['title']!),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedAmbulanceType = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Show the selected ambulance type subtitle separately
                    if (_selectedAmbulanceType.isNotEmpty &&
                        _selectedAmbulanceTypeSubtitle.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAmbulanceTypeSubtitle,
                                style: TextStyle(
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24),

                    // Equipment Section
                    FormLabelText(text: "Equipment and Facilities"),
                    SizedBox(height: 8),
                    SelectableButton(
                      title: "Oxygen Cylinders",
                      subtitle: "Portable and fixed oxygen supply systems",
                      isSelected: _selectedEquipment.contains("OXYGEN"),
                      onTap: () => setState(() {
                        if (_selectedEquipment.contains("OXYGEN")) {
                          _selectedEquipment.remove("OXYGEN");
                        } else {
                          _selectedEquipment.add("OXYGEN");
                        }
                      }),
                    ),
                    SelectableButton(
                      title: "Defibrillators",
                      subtitle: "Automated External Defibrillator (AED)",
                      isSelected: _selectedEquipment.contains("DEFIBRILLATOR"),
                      onTap: () => setState(() {
                        if (_selectedEquipment.contains("DEFIBRILLATOR")) {
                          _selectedEquipment.remove("DEFIBRILLATOR");
                        } else {
                          _selectedEquipment.add("DEFIBRILLATOR");
                        }
                      }),
                    ),
                    SelectableButton(
                      title: "Ventilators",
                      subtitle: "Portable mechanical ventilation system",
                      isSelected: _selectedEquipment.contains("VENTILATOR"),
                      onTap: () => setState(() {
                        if (_selectedEquipment.contains("VENTILATOR")) {
                          _selectedEquipment.remove("VENTILATOR");
                        } else {
                          _selectedEquipment.add("VENTILATOR");
                        }
                      }),
                    ),
                    SelectableButton(
                      title: "Emergency Medical Kit",
                      subtitle: "Complete first aid and emergency supplies",
                      isSelected: _selectedEquipment.contains("EMERGENCY_KIT"),
                      onTap: () => setState(() {
                        if (_selectedEquipment.contains("EMERGENCY_KIT")) {
                          _selectedEquipment.remove("EMERGENCY_KIT");
                        } else {
                          _selectedEquipment.add("EMERGENCY_KIT");
                        }
                      }),
                    ),
                    SizedBox(height: 40),

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
