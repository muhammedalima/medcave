import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/editprofiledriver.dart';
import 'package:medcave/common/database/model/User/driver_db.dart';
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

  String getAmbulanceTypeFullForm(String ambulanceType) {
    final lowerCaseType = ambulanceType.toLowerCase();
    
    if (lowerCaseType.contains('bls') || lowerCaseType.contains('basic')) {
      return 'Basic Life Support';
    } else if (lowerCaseType.contains('als') || lowerCaseType.contains('advanced')) {
      return 'Advanced Life Support';
    } else if (lowerCaseType.contains('pts') || lowerCaseType.contains('patient')) {
      return 'Patient Transport Service';
    } else if (lowerCaseType.contains('micu') || lowerCaseType.contains('mobile intensive')) {
      return 'Mobile Intensive Care Unit';
    } else if (lowerCaseType.contains('neonatal') || lowerCaseType.contains('nicu')) {
      return 'Neonatal Intensive Care Unit';
    } else {
      return ambulanceType; // Return original if no match
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

    if (_driverData == null) {
      return Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColor.backgroundWhite,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'No driver profile data found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverProfileEdit(),
                  ),
                );
              },
              child: const Text('Create Profile'),
            ),
          ],
        ),
      );
    }

    // Get values from database with null handling
    final vehicleId = _driverData?['vehicleRegistrationNumber'] ?? '';
    final driverLicense = _driverData?['driverLicense'] ?? '';
    final ambulanceType = _driverData?['ambulanceType'] ?? '';
    
    // Handle equipment list correctly
    List<dynamic> equipmentList = [];
    if (_driverData?['equipment'] != null) {
      if (_driverData!['equipment'] is List) {
        equipmentList = _driverData!['equipment'];
      }
    }

    // Determine ambulance prefix and full form based on type
    String ambulancePrefix = '';
    if (ambulanceType.toLowerCase().contains('basic') || 
        ambulanceType.toLowerCase().contains('bls')) {
      ambulancePrefix = 'BLS';
    } else if (ambulanceType.toLowerCase().contains('advanced') || 
               ambulanceType.toLowerCase().contains('als')) {
      ambulancePrefix = 'ALS';
    } else if (ambulanceType.toLowerCase().contains('patient') || 
               ambulanceType.toLowerCase().contains('pts')) {
      ambulancePrefix = 'PTS';
    } else if (ambulanceType.toLowerCase().contains('mobile') || 
               ambulanceType.toLowerCase().contains('micu')) {
      ambulancePrefix = 'MICU';
    }

    // Get the full form
    final ambulanceTypeFullForm = getAmbulanceTypeFullForm(ambulanceType);

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
            vehicleId.isNotEmpty ? 
                (ambulancePrefix.isNotEmpty ? '$ambulancePrefix - $vehicleId' : vehicleId) : 
                'Vehicle Registration Number Not Set',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ambulanceType.isNotEmpty ? 
                ambulanceTypeFullForm : 
                'Ambulance Type Not Set',
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
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverProfileEdit(),
                  ),
                );
                // Refresh data when returning from edit screen
                _loadDriverData();
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
          if (equipmentList.isNotEmpty) ...[
            const Text(
              'Equipment:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _buildEquipmentChips(equipmentList),
            ),
          ] else ...[
            const Text(
              'No equipment listed',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],

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
                driverLicense.isNotEmpty ? 
                    driverLicense : 
                    'Not Set',
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
        color: AppColor.secondaryBackgroundWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        item.capitalize(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }
}