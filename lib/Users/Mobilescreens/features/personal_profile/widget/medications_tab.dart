import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/active_medicine.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/past_medicine_list.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/reminder_tab.dart';
import 'package:medcave/common/database/User/medicine/user_medicine.dart';
import 'package:medcave/common/database/User/reminder/reminder_db.dart';

class MedicationsTab extends StatefulWidget {
  final String userId;
  
  const MedicationsTab({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<MedicationsTab> createState() => _MedicationsTabState();
}

class _MedicationsTabState extends State<MedicationsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Medicine> activeMedicines = [];
  List<Medicine> pastMedicines = [];
  bool isLoading = true;
  late ReminderDatabase _reminderDatabase;
  late ReminderModel _reminderData;

  @override
  void initState() {
    super.initState();
    _reminderDatabase = ReminderDatabase();
    _loadMedicinesAndReminders();
  }

  Future<void> _loadMedicinesAndReminders() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Load reminder data
      await _loadReminderData();
      
      // Load medicines data
      await _loadMedicines();
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error in _loadMedicinesAndReminders: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadReminderData() async {
    try {
      // Try to fetch existing reminder data
      _reminderData = await _reminderDatabase.fetchReminderData(widget.userId);
      
      // If no data exists or some default times are missing, set default times
      if (_reminderData.morningBeforeFood == null || 
          _reminderData.morningAfterFood == null || 
          _reminderData.noonBeforeFood == null || 
          _reminderData.noonAfterFood == null || 
          _reminderData.nightBeforeFood == null || 
          _reminderData.nightAfterFood == null) {
        
        // Create a model with default values for any missing times
        final defaultModel = ReminderModel(
          morningBeforeFood: _reminderData.morningBeforeFood ?? const TimeOfDay(hour: 7, minute: 30),
          morningAfterFood: _reminderData.morningAfterFood ?? const TimeOfDay(hour: 9, minute: 0),
          noonBeforeFood: _reminderData.noonBeforeFood ?? const TimeOfDay(hour: 12, minute: 30),
          noonAfterFood: _reminderData.noonAfterFood ?? const TimeOfDay(hour: 14, minute: 0),
          nightBeforeFood: _reminderData.nightBeforeFood ?? const TimeOfDay(hour: 19, minute: 30),
          nightAfterFood: _reminderData.nightAfterFood ?? const TimeOfDay(hour: 21, minute: 0),
        );
        
        // Save the default values to database
        await _reminderDatabase.saveReminderData(widget.userId, defaultModel);
        
        // Update local state
        _reminderData = defaultModel;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reminder data: $e');
      }
      
      // If error, set default values in memory but don't try to save to database again
      _reminderData = ReminderModel(
        morningBeforeFood: const TimeOfDay(hour: 7, minute: 30),
        morningAfterFood: const TimeOfDay(hour: 9, minute: 0),
        noonBeforeFood: const TimeOfDay(hour: 12, minute: 30),
        noonAfterFood: const TimeOfDay(hour: 14, minute: 0),
        nightBeforeFood: const TimeOfDay(hour: 19, minute: 30),
        nightAfterFood: const TimeOfDay(hour: 21, minute: 0),
      );
    }
  }

  Future<void> _updateReminderTime(String type, String mealTime, TimeOfDay time) async {
    try {
      // Update locally first for immediate UI update
      setState(() {
        _reminderData = _reminderData.copyWith(
          type: type,
          mealTime: mealTime,
          time: time,
        );
      });
      
      // Then update in the database
      await _reminderDatabase.updateReminderTime(
        widget.userId,
        type,
        mealTime,
        time,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder time updated successfully')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating reminder time: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reminder time: $e')),
      );
    }
  }

  Future<void> _loadMedicines() async {
    try {
      if (widget.userId.isNotEmpty) {
        // Load active medicines
        final activeMedicinesSnapshot = await _firestore
            .collection('medicines')
            .where('userId', isEqualTo: widget.userId)
            .where('isActive', isEqualTo: true)
            .get();
        
        // Load past medicines
        final pastMedicinesSnapshot = await _firestore
            .collection('medicines')
            .where('userId', isEqualTo: widget.userId)
            .where('isActive', isEqualTo: false)
            .limit(5) // Limit to 5 for the preview
            .get();
        
        setState(() {
          activeMedicines = activeMedicinesSnapshot.docs
              .map((doc) => Medicine.fromMap(doc.data()))
              .toList();
          
          pastMedicines = pastMedicinesSnapshot.docs
              .map((doc) => Medicine.fromMap(doc.data()))
              .toList();
          
          // Use dummy data if empty
          if (activeMedicines.isEmpty) {
            activeMedicines = _createDummyActiveMedicines();
          }
          
          if (pastMedicines.isEmpty) {
            pastMedicines = _createDummyPastMedicines();
          }
        });
      } else {
        setState(() {
          // Use dummy data
          activeMedicines = _createDummyActiveMedicines();
          pastMedicines = _createDummyPastMedicines();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading medicines: $e');
      }
      setState(() {
        // Use dummy data on error
        activeMedicines = _createDummyActiveMedicines();
        pastMedicines = _createDummyPastMedicines();
      });
    }
  }

  // Existing methods remain unchanged
  List<Medicine> _createDummyActiveMedicines() {
    // Existing implementation unchanged
    return [
      Medicine(
        id: 'sample-1',
        userId: '',
        name: 'Paracetamol',
        schedule: ['morning', 'noon', 'night'],
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        isActive: true,
      ),
      Medicine(
        id: 'sample-2',
        userId: '',
        name: 'Citrazin',
        schedule: ['night'],
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 1)),
        isActive: true,
      ),
      Medicine(
        id: 'sample-3',
        userId: '',
        name: 'Vitamin A',
        schedule: ['morning', 'noon'],
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime(2024, 2, 22),
        isActive: true,
      ),
      Medicine(
        id: 'sample-4',
        userId: '',
        name: 'Omeprazole',
        schedule: ['morning'],
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
      ),
      Medicine(
        id: 'sample-5',
        userId: '',
        name: 'Aspirin',
        schedule: ['noon'],
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 25)),
        isActive: true,
      ),
    ];
  }

  List<Medicine> _createDummyPastMedicines() {
    // Existing implementation unchanged
    final pastDate = DateTime(2023, 11, 21);
    final endDate = DateTime(2023, 11, 25);
    
    return [
      Medicine(
        id: 'past-sample-1',
        userId: '',
        name: 'Paracetamol',
        schedule: ['morning', 'noon', 'night'],
        startDate: pastDate,
        endDate: endDate,
        isActive: false,
      ),
      Medicine(
        id: 'past-sample-2',
        userId: '',
        name: 'Citrazin',
        schedule: ['night'],
        startDate: pastDate,
        endDate: endDate,
        isActive: false,
      ),
      Medicine(
        id: 'past-sample-3',
        userId: '',
        name: 'Vitamin C',
        schedule: ['morning', 'night'],
        startDate: pastDate,
        endDate: endDate,
        isActive: false,
      ),
    ];
  }

  Future<void> _saveMedicine(
    String medicineName, 
    List<String> intakeTimes, 
    DateTime startDate,
    DateTime? endDate,
  ) async {
    // Existing implementation unchanged
    try {
      setState(() {
        isLoading = true;
      });

      // Create a new medicine object
      final newMedicine = Medicine(
        id: '', // This will be set by Firestore
        userId: widget.userId,
        name: medicineName,
        schedule: intakeTimes,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
      );

      // Add to Firestore
      final docRef = await _firestore.collection('medicines').add(newMedicine.toMap());
      
      // Update the id field with the Firestore document ID
      await docRef.update({'id': docRef.id});
      
      // Refresh the medicines list
      await _loadMedicines();
      
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine added successfully')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving medicine: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding medicine: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showViewAllPastMedicines() {
    // Existing implementation unchanged
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View all past medicines')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // New Reminder Time Section with the updated widget
          ReminderTimeSection(
            reminderData: _reminderData,
            onTimeChanged: _updateReminderTime,
          ),
          
          // Medicines section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Medicines Section
                ActiveMedicinesSection(
                  medicines: activeMedicines,
                  onAddPressed: () => _showAddMedicineDialog(),
                ),
                
                const SizedBox(height: 24),
                
                // Past Medicines Section
                PastMedicinesSection(
                  medicines: pastMedicines,
                  onViewAllPressed: _showViewAllPastMedicines,
                ),
                
                // Bottom padding
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineDialog() {
    // Existing implementation unchanged
    final medicineNameController = TextEditingController();
    List<String> selectedIntakeTimes = [];
    DateTime selectedStartDate = DateTime.now();
    DateTime? selectedEndDate;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Medicine'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: medicineNameController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Intake Time:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: const Text('Morning'),
                      value: selectedIntakeTimes.contains('morning'),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedIntakeTimes.add('morning');
                          } else {
                            selectedIntakeTimes.remove('morning');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Noon'),
                      value: selectedIntakeTimes.contains('noon'),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedIntakeTimes.add('noon');
                          } else {
                            selectedIntakeTimes.remove('noon');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Night'),
                      value: selectedIntakeTimes.contains('night'),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedIntakeTimes.add('night');
                          } else {
                            selectedIntakeTimes.remove('night');
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Duration:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedStartDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null && pickedDate != selectedStartDate) {
                          setState(() {
                            selectedStartDate = pickedDate;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('End Date (Optional)'),
                      subtitle: Text(selectedEndDate != null 
                          ? DateFormat('dd/MM/yyyy').format(selectedEndDate!) 
                          : 'Not set'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedEndDate ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: selectedStartDate,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedEndDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (medicineNameController.text.trim().isNotEmpty &&
                        selectedIntakeTimes.isNotEmpty) {
                      _saveMedicine(
                        medicineNameController.text.trim(),
                        selectedIntakeTimes,
                        selectedStartDate,
                        selectedEndDate,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a medicine name and select at least one intake time'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}