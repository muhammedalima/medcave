import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/editprofiledriver.dart';
import 'package:medcave/common/database/User/driver_db.dart';
import 'package:medcave/config/colors/appcolor.dart';

class AmbulanceDriverProfile extends StatefulWidget {
  const AmbulanceDriverProfile({Key? key}) : super(key: key);

  @override
  State<AmbulanceDriverProfile> createState() => _AmbulanceDriverProfileState();
}

class _AmbulanceDriverProfileState extends State<AmbulanceDriverProfile> {
  bool _isLoading = true;
  Map<String, dynamic>? _driverData;

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
      final data = await DriverDatabase.getCurrentDriverData();
      setState(() {
        _driverData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load driver data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Default values if data is missing or null
    final vehicleId =
        _driverData?['vehicleRegistrationNumber'] ?? 'BLC - KL 01AB 1234';
    final driverLicense = _driverData?['driverLicense'] ?? 'KL 49000 5000';
    final ambulanceType = _driverData?['ambulanceType'] ?? 'Ambulance';
    final equipment = _driverData?['equipment'] as List<dynamic>? ??
        [
          'Defibrillators',
          'Oxygen Cylinders',
          'Ventilators',
          'Emergency Medical Kit'
        ];

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColor.backgroundWhite,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle ID and ambulance type
          Text(
            'BLC - $vehicleId',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Basic Life Support - $ambulanceType',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),

          // Edit Profile Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverProfileEdit(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Edit Driver Profile',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Equipment Chips
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _buildEquipmentChips(equipment),
          ),

          const SizedBox(height: 16),

          // Driver License
          Row(
            children: [
              Text(
                'Driver license no : ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                driverLicense,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEquipmentChips(List<dynamic> equipment) {
    return equipment.map((item) {
      return CustomCard(item: item.toString());
    }).toList();
  }
}

extension StringExtension on String {
  String capitalize() {
    return isNotEmpty
        ? this[0].toUpperCase() + substring(1).toLowerCase()
        : this;
  }
}

class CustomCard extends StatelessWidget {
  final String item;

  const CustomCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.secondaryBackgroundWhite, // Light grey color from image
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        item.capitalize(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.black, // Matches the text color from image
        ),
      ),
    );
  }
}
