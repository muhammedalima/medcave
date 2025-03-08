import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/OnBoarding/widget/formlabel.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/OnBoarding/widget/onboardinginput.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/OnBoarding/widget/onboardingwidget_arrow.dart';
import 'package:medcave/Users/Mobilescreens/Starting_Screen/OnBoarding/widget/selectableButtton.dart';
import 'package:medcave/Users/Mobilescreens/bottom_navigation_bar/bottom_navigation_bar.dart';
import 'package:medcave/database/User/user_db.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  int _currentPage = 0;
  String selectedAmbulanceType = '';
  List<String> selectedEquipment = [];
  OnboardingData _data = OnboardingData();
  bool _isSaving = false;
  bool _keyboardVisible = false;

  Future<void> _saveOnboardingData() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      bool success = await OnboardingService.saveOnboardingData(
        _data,
        selectedAmbulanceType,
        selectedEquipment,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving data. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Add listener for keyboard visibility changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      setState(() {
        _keyboardVisible = keyboardHeight > 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _firstForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const FormLabelText(text: "What's your name?"),
          const SizedBox(height: 8),
          InputFieldContainer(
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
          const FormLabelText(text: 'Are you driving an ambulance?'),
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
          const FormLabelText(text: "What's your phone number?"),
          const SizedBox(height: 8),
          InputFieldContainer(
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
          const FormLabelText(text: "What's your driving license number?"),
          const SizedBox(height: 8),
          InputFieldContainer(
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
        controller: _scrollController,
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
            const FormLabelText(text: "Vehicle Registration Number"),
            const SizedBox(height: 8),
            InputFieldContainer(
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
            const FormLabelText(text: "Ambulance Type"),
            const SizedBox(height: 8),
            SelectableButton(
              title: "Basic Life Support",
              subtitle: "BLS - Essential medical equipment and trained staff",
              isSelected: selectedAmbulanceType == "BLS",
              onTap: () => setState(() => selectedAmbulanceType = "BLS"),
            ),
            SelectableButton(
              title: "Advanced Life Support",
              subtitle: "ALS - Advanced medical equipment and specialized staff",
              isSelected: selectedAmbulanceType == "ALS",
              onTap: () => setState(() => selectedAmbulanceType = "ALS"),
            ),
            SelectableButton(
              title: "Patient Transport Vehicle",
              subtitle: "PTV - Basic medical support for non-emergency transport",
              isSelected: selectedAmbulanceType == "PTV",
              onTap: () => setState(() => selectedAmbulanceType = "PTV"),
            ),
            SelectableButton(
              title: "Neonatal Ambulance",
              subtitle: "Specialized equipment for newborn care",
              isSelected: selectedAmbulanceType == "NEONATAL",
              onTap: () => setState(() => selectedAmbulanceType = "NEONATAL"),
            ),
            const SizedBox(height: 24),
            const FormLabelText(text: "Equipment and Facilities"),
            const SizedBox(height: 8),
            SelectableButton(
              title: "Oxygen Cylinders",
              subtitle: "Portable and fixed oxygen supply systems",
              isSelected: selectedEquipment.contains("OXYGEN"),
              onTap: () => setState(() {
                if (selectedEquipment.contains("OXYGEN")) {
                  selectedEquipment.remove("OXYGEN");
                } else {
                  selectedEquipment.add("OXYGEN");
                }
              }),
            ),
            SelectableButton(
              title: "Defibrillators",
              subtitle: "Automated External Defibrillator (AED)",
              isSelected: selectedEquipment.contains("DEFIBRILLATOR"),
              onTap: () => setState(() {
                if (selectedEquipment.contains("DEFIBRILLATOR")) {
                  selectedEquipment.remove("DEFIBRILLATOR");
                } else {
                  selectedEquipment.add("DEFIBRILLATOR");
                }
              }),
            ),
            SelectableButton(
              title: "Ventilators",
              subtitle: "Portable mechanical ventilation system",
              isSelected: selectedEquipment.contains("VENTILATOR"),
              onTap: () => setState(() {
                if (selectedEquipment.contains("VENTILATOR")) {
                  selectedEquipment.remove("VENTILATOR");
                } else {
                  selectedEquipment.add("VENTILATOR");
                }
              }),
            ),
            SelectableButton(
              title: "Emergency Medical Kit",
              subtitle: "Complete first aid and emergency supplies",
              isSelected: selectedEquipment.contains("EMERGENCY_KIT"),
              onTap: () => setState(() {
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

  void _handleNext() async {
    if (_formKey.currentState!.validate()) {
      // If user is not an ambulance driver and we're on page 1 (phone number)
      if (!_data.isAmbulanceDriver && _currentPage == 1) {
        // Save the data and proceed to home
        await _saveOnboardingData();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CustomNavigationBar(),
            ),
          );
        }
        return;
      }

      // For ambulance drivers, or for the first page for all users
      if (_currentPage == 3 ||
          (_currentPage == 1 && !_data.isAmbulanceDriver)) {
        // On the last page, save all data
        await _saveOnboardingData();
        // Navigate to home screen or next screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CustomNavigationBar(),
            ),
          );
        }
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Get the total pages based on whether user is ambulance driver or not
  int get _totalPages => _data.isAmbulanceDriver ? 4 : 2;

  @override
  Widget build(BuildContext context) {
    // Get keyboard height to adjust the form
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // Update keyboard visibility
    bool keyboardIsVisible = keyboardHeight > 0;
    if (_keyboardVisible != keyboardIsVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _keyboardVisible = keyboardIsVisible;
        });
      });
    }

    return Scaffold(
      // Resizeability to avoid keyboard overlap
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF7B7BEA),
      body: SafeArea(
        // Using a SingleChildScrollView with resizeToAvoidBottomInset: true
        // allows the content to scroll when keyboard appears
        child: SingleChildScrollView(
          // This physics makes the scrolling more responsive
          physics: const ClampingScrollPhysics(),
          // Add padding at the bottom equal to keyboard height to ensure
          // content is above the keyboard
          padding:
              EdgeInsets.only(bottom: keyboardHeight > 0 ? keyboardHeight : 0),
          child: Column(
            children: [
              // Header and logo section - hide if keyboard is visible to save space
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: keyboardIsVisible ? 20 : 40,
                child: keyboardIsVisible ? null : const SizedBox(height: 40),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: keyboardIsVisible ? 0 : null,
                child: keyboardIsVisible
                    ? const SizedBox.shrink()
                    : const Padding(
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
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: keyboardIsVisible ? 0 : 300,
                child: keyboardIsVisible
                    ? const SizedBox.shrink()
                    : Image.asset(
                        'assets/ambulance.png',
                        height: 300,
                        fit: BoxFit.contain,
                      ),
              ),
              // Form container section
              Container(
                // Adjust height dynamically based on keyboard visibility
                height: keyboardIsVisible
                    ? screenHeight -
                        keyboardHeight -
                        80 // Give more space for form
                    : screenHeight * 0.5,
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
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _firstForm(),
                      _secondForm(),
                      if (_data.isAmbulanceDriver) _thirdForm(),
                      if (_data.isAmbulanceDriver) _fourthForm(),
                    ],
                  ),
                ),
              ),
              // Extra space at the bottom for the button sheet to sit on
              SizedBox(height: keyboardIsVisible ? 0 : 80),
            ],
          ),
        ),
      ),
      // Position the bottom sheet above the keyboard
      bottomSheet: Padding(
        // Add padding to avoid keyboard
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                OnboardingArrowIcon(
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
              if (_currentPage < _totalPages - 1)
                OnboardingArrowIcon(
                  rotateAngle: 0.8,
                  onclick: _handleNext,
                )
              else
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B7BEA),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
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
      ),
    );
  }
}