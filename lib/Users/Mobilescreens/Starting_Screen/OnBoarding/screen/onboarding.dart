import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/OnBoarding/widget/onboardingwidget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingData {
  final String driverLicense;
  final String phoneNumber;
  final String name;
  final bool isAmbulanceDriver;
  final String vehicleRegistrationNumber;
  final String ambulanceType;
  final List<String> equipment;
  bool _isSaving = false;

  OnboardingData({
    this.driverLicense = '',
    this.phoneNumber = '',
    this.name = '',
    this.isAmbulanceDriver = false,
    this.vehicleRegistrationNumber = '',
    this.ambulanceType = '',
    this.equipment = const [],
  });
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  String selectedAmbulanceType = '';
  List<String> selectedEquipment = [];
  OnboardingData _data = OnboardingData();

  Future<void> _saveOnboardingData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'driverLicense': _data.driverLicense,
          'phoneNumber': _data.phoneNumber,
          'name': _data.name,
          'isAmbulanceDriver': _data.isAmbulanceDriver,
          'vehicleRegistrationNumber': _data.vehicleRegistrationNumber,
          'ambulanceType': selectedAmbulanceType,
          'equipment': selectedEquipment,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _firstForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "What's your name?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: TextFormField(
              initialValue: _data.name,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter your full name',
                hintStyle: TextStyle(
                  color: Colors.black38,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                if (value.length < 3) {
                  return 'Name must be at least 3 characters long';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _data = OnboardingData(
                    name: value,
                    phoneNumber: _data.phoneNumber,
                    driverLicense: _data.driverLicense,
                    isAmbulanceDriver: _data.isAmbulanceDriver,
                    vehicleRegistrationNumber: _data.vehicleRegistrationNumber,
                    ambulanceType: _data.ambulanceType,
                    equipment: _data.equipment,
                    
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Are you driving an ambulance?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _data = OnboardingData(
                        name: _data.name,
                        phoneNumber: _data.phoneNumber,
                        driverLicense: _data.driverLicense,
                        isAmbulanceDriver: true,
                        vehicleRegistrationNumber:
                            _data.vehicleRegistrationNumber,
                        ambulanceType: _data.ambulanceType,
                        equipment: _data.equipment,
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _data.isAmbulanceDriver
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFFF3F4F6),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Yes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _data = OnboardingData(
                        name: _data.name,
                        phoneNumber: _data.phoneNumber,
                        driverLicense: _data.driverLicense,
                        isAmbulanceDriver: false,
                        vehicleRegistrationNumber:
                            _data.vehicleRegistrationNumber,
                        ambulanceType: _data.ambulanceType,
                        equipment: _data.equipment,
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_data.isAmbulanceDriver
                        ? Colors.black
                        : const Color(0xFFF3F4F6),
                    foregroundColor:
                        !_data.isAmbulanceDriver ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'No',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secondForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "What's your phone number?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: TextFormField(
              initialValue: _data.phoneNumber,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '+91 1234567890',
                hintStyle: TextStyle(
                  color: Colors.black38,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                // Basic phone number validation
                if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _data = OnboardingData(
                    name: _data.name,
                    phoneNumber: value,
                    driverLicense: _data.driverLicense,
                    isAmbulanceDriver: _data.isAmbulanceDriver,
                    vehicleRegistrationNumber: _data.vehicleRegistrationNumber,
                    ambulanceType: _data.ambulanceType,
                    equipment: _data.equipment,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _thirdForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "What's your driving license number?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: TextFormField(
              initialValue: _data.driverLicense,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'KL 49000 5000',
                hintStyle: TextStyle(
                  color: Colors.black38,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your license number';
                }
                if (value.length < 8) {
                  return 'Please enter a valid license number';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _data = OnboardingData(
                    name: _data.name,
                    phoneNumber: _data.phoneNumber,
                    driverLicense: value.toUpperCase(),
                    isAmbulanceDriver: _data.isAmbulanceDriver,
                    vehicleRegistrationNumber: _data.vehicleRegistrationNumber,
                    ambulanceType: _data.ambulanceType,
                    equipment: _data.equipment,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _fourthForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Vehicle Details",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Vehicle Registration Number",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: TextFormField(
                initialValue: _data.vehicleRegistrationNumber,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'KL 01 AB 1234',
                  hintStyle: TextStyle(
                    color: Colors.black38,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle registration number';
                  }
                  if (value.length < 8) {
                    return 'Please enter a valid registration number';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _data = OnboardingData(
                      name: _data.name,
                      phoneNumber: _data.phoneNumber,
                      driverLicense: _data.driverLicense,
                      isAmbulanceDriver: _data.isAmbulanceDriver,
                      vehicleRegistrationNumber: value.toUpperCase(),
                      ambulanceType: _data.ambulanceType,
                      equipment: _data.equipment,
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Ambulance Type",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildSelectableButton(
              "Basic Life Support",
              "BLS - Essential medical equipment and trained staff",
              selectedAmbulanceType == "BLS",
              () => setState(() => selectedAmbulanceType = "BLS"),
            ),
            _buildSelectableButton(
              "Advanced Life Support",
              "ALS - Advanced medical equipment and specialized staff",
              selectedAmbulanceType == "ALS",
              () => setState(() => selectedAmbulanceType = "ALS"),
            ),
            _buildSelectableButton(
              "Patient Transport Vehicle",
              "PTV - Basic medical support for non-emergency transport",
              selectedAmbulanceType == "PTV",
              () => setState(() => selectedAmbulanceType = "PTV"),
            ),
            _buildSelectableButton(
              "Neonatal Ambulance",
              "Specialized equipment for newborn care",
              selectedAmbulanceType == "NEONATAL",
              () => setState(() => selectedAmbulanceType = "NEONATAL"),
            ),
            const SizedBox(height: 24),
            const Text(
              "Equipment and Facilities",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildSelectableButton(
              "Oxygen Cylinders",
              "Portable and fixed oxygen supply systems",
              selectedEquipment.contains("OXYGEN"),
              () => setState(() {
                if (selectedEquipment.contains("OXYGEN")) {
                  selectedEquipment.remove("OXYGEN");
                } else {
                  selectedEquipment.add("OXYGEN");
                }
              }),
            ),
            _buildSelectableButton(
              "Defibrillators",
              "Automated External Defibrillator (AED)",
              selectedEquipment.contains("DEFIBRILLATOR"),
              () => setState(() {
                if (selectedEquipment.contains("DEFIBRILLATOR")) {
                  selectedEquipment.remove("DEFIBRILLATOR");
                } else {
                  selectedEquipment.add("DEFIBRILLATOR");
                }
              }),
            ),
            _buildSelectableButton(
              "Ventilators",
              "Portable mechanical ventilation system",
              selectedEquipment.contains("VENTILATOR"),
              () => setState(() {
                if (selectedEquipment.contains("VENTILATOR")) {
                  selectedEquipment.remove("VENTILATOR");
                } else {
                  selectedEquipment.add("VENTILATOR");
                }
              }),
            ),
            _buildSelectableButton(
              "Emergency Medical Kit",
              "Complete first aid and emergency supplies",
              selectedEquipment.contains("EMERGENCY_KIT"),
              () => setState(() {
                if (selectedEquipment.contains("EMERGENCY_KIT")) {
                  selectedEquipment.remove("EMERGENCY_KIT");
                } else {
                  selectedEquipment.add("EMERGENCY_KIT");
                }
              }),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableButton(
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7B7BEA).withOpacity(0.1)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF7B7BEA) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF7B7BEA),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNext() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPage == 3) {
        // On the last page, save all data
        setState(() {
          _data = OnboardingData(
            driverLicense: _data.driverLicense,
            phoneNumber: _data.phoneNumber,
            name: _data.name,
            isAmbulanceDriver: _data.isAmbulanceDriver,
            vehicleRegistrationNumber: _data.vehicleRegistrationNumber,
          );
        });
        
        await _saveOnboardingData();
        // Navigate to home screen or next screen
        if (mounted) {
          Navigator.of(context)
              .pushReplacementNamed('/home'); // Adjust route as needed
        }
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B7BEA),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Welcome to MedCave Ambulance Service!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Image.asset(
                'assets/ambulance.png',
                height: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 5),
              Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _firstForm(),
                      _secondForm(),
                      _thirdForm(),
                      _fourthForm(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              Onboardingarrrowicon(
                rotateAngle: -2.4,
                onclick: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              )
            else
              const SizedBox.shrink(),
            if (_currentPage < 3)
              Onboardingarrrowicon(
                rotateAngle: 0.8,
                onclick: _handleNext,
              )
            else
              ElevatedButton(
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B7BEA),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Complete',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}