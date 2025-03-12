import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


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

  @override
  void initState() {
    super.initState();
    _loadMedicines();
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
            .get();
        
        setState(() {
          activeMedicines = activeMedicinesSnapshot.docs
              .map((doc) => Medicine.fromMap(doc.data()))
              .toList();
          
          pastMedicines = pastMedicinesSnapshot.docs
              .map((doc) => Medicine.fromMap(doc.data()))
              .toList();
          
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading medicines: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToAddMedicine() {
    _showAddMedicineDialog();
  }

  void _showAddMedicineDialog() {
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

  Future<void> _saveMedicine(
    String medicineName, 
    List<String> intakeTimes, 
    DateTime startDate,
    DateTime? endDate,
  ) async {
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
        dosage: '', // Optional field that could be added later
        notes: '', // Optional field that could be added later
      );

      // Add to Firestore
      final docRef = await _firestore.collection('medicines').add(newMedicine.toMap());
      
      // Update the id field with the Firestore document ID
      await docRef.update({'id': docRef.id});
      
      // Refresh the medicines list
      await _loadMedicines();
      
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

  String _formatSchedule(List<String> schedule) {
    return schedule.join(' / ');
  }

  String _formatDateRange(DateTime startDate, DateTime? endDate) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    if (endDate != null) {
      return '${dateFormat.format(startDate)}-${dateFormat.format(endDate)}';
    }
    return 'From ${dateFormat.format(startDate)}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Medications Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Taking Medicine',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: _navigateToAddMedicine,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // List of Current Medications
          Expanded(
            flex: 1,
            child: activeMedicines.isEmpty 
                ? _buildEmptyActiveMedicines() 
                : ListView.builder(
                    itemCount: activeMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = activeMedicines[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  medicine.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () {
                                  // Edit medicine functionality could be added later
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 4,
                                  children: medicine.schedule.map((time) => 
                                    Chip(
                                      label: Text(
                                        time,
                                        style: const TextStyle(fontSize: 12, color: Colors.white),
                                      ),
                                      padding: EdgeInsets.zero,
                                      backgroundColor: _getTimeColor(time),
                                      visualDensity: VisualDensity.compact,
                                    )
                                  ).toList(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDateRange(medicine.startDate, medicine.endDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                        ],
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Past Medications Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Past Medicines',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  // View all past medications
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text(
                  'view all',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // List of Past Medications
          Expanded(
            flex: 1,
            child: pastMedicines.isEmpty
                ? _buildEmptyPastMedicines()
                : ListView.builder(
                    itemCount: pastMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = pastMedicines[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatSchedule(medicine.schedule)} - ${_formatDateRange(medicine.startDate, medicine.endDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActiveMedicines() {
    final sampleMedicines = [
      {
        'name': 'Paracetamol',
        'schedule': ['morning', 'noon', 'night'],
      },
      {
        'name': 'Citrazin',
        'schedule': ['night'],
      },
      {
        'name': 'Vitamin A',
        'schedule': ['morning'],
      },
    ];
    
    return ListView.builder(
      itemCount: sampleMedicines.length,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sampleMedicines[index]['name'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (sampleMedicines[index]['schedule'] as List<String>).join(' / '),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyPastMedicines() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paracetamol',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'morning / noon / night - 21/11/2002-25/11/2002',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
          ],
        );
      },
    );
  }

  Color _getTimeColor(String time) {
    switch (time) {
      case 'morning':
        return Colors.orange;
      case 'noon':
        return Colors.blue;
      case 'night':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

// Assuming this is what your Medicine class looks like, 
// if not please adjust according to your actual Medicine class
class Medicine {
  final String id;
  final String userId;
  final String name;
  final List<String> schedule;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String dosage;
  final String notes;

  Medicine({
    required this.id,
    required this.userId,
    required this.name,
    required this.schedule,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.dosage = '',
    this.notes = '',
  });

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      schedule: List<String>.from(map['schedule'] ?? []),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      isActive: map['isActive'] ?? true,
      dosage: map['dosage'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'schedule': schedule,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'dosage': dosage,
      'notes': notes,
    };
  }
}