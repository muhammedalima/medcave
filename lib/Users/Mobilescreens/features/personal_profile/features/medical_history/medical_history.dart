import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/features/medical_history/widget/add_medical_history_popup.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/features/medical_history/widget/history_detail_popup.dart';
import 'package:medcave/common/database/model/User/medicine/user_medical_record.dart';
import 'package:medcave/config/fonts/font.dart';

class MedicalHistoryTab extends StatefulWidget {
  final String userId;

  const MedicalHistoryTab({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<MedicalHistoryTab> createState() => _MedicalHistoryTabState();
}

class _MedicalHistoryTabState extends State<MedicalHistoryTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<MedicalRecord> medicalRecords = [];

  @override
  void initState() {
    super.initState();
    _loadMedicalRecords();
  }

  // Load medical records from Firestore
  Future<void> _loadMedicalRecords() async {
    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('userdata')
          .doc(widget.userId)
          .collection('medicinehistory')
          .orderBy('date', descending: true)
          .get();

      final records = snapshot.docs.map((doc) {
        return MedicalRecord.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      if (mounted) {
        setState(() {
          medicalRecords = records;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading medical records: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load medical records')),
        );
      }
    }
  }

  // Show add medical record popup
  void _showAddMedicalRecordPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddMedicalRecordPopup(
        onAdd: (heading, description, date) {
          _addNewRecord(heading, description, date);
        },
      ),
    );
  }

  // Show medical history popup for a record
  void _showMedicalHistoryPopup(MedicalRecord record) {
    showDialog(
      context: context,
      builder: (context) => MedicalHistoryPopup(
        record: record,
        onEdit: (heading, description, date) {
          _updateRecord(record.id, heading, description, date);
        },
        onDelete: () {
          _deleteRecord(record.id);
        },
      ),
    );
  }

  // Add a new medical record
  Future<void> _addNewRecord(
      String heading, String description, DateTime date) async {
    try {
      // Create document reference
      final docRef = _firestore
          .collection('userdata')
          .doc(widget.userId)
          .collection('medicinehistory')
          .doc();

      // Create new record
      final newRecord = MedicalRecord(
        id: docRef.id,
        heading: heading,
        description: description,
        date: date,
        userId: widget.userId,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await docRef.set(newRecord.toMap());

      // Update local state
      setState(() {
        medicalRecords.insert(0, newRecord);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical record added successfully')),
      );
    } catch (e) {
      print('Error adding medical record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add medical record')),
      );
    }
  }

  // Update an existing record
  Future<void> _updateRecord(
      String id, String heading, String description, DateTime date) async {
    try {
      // Find the record in the local list
      final index = medicalRecords.indexWhere((record) => record.id == id);
      if (index == -1) return;

      // Create updated record
      final updatedRecord = medicalRecords[index].copyWith(
        heading: heading,
        description: description,
        date: date,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _firestore
          .collection('userdata')
          .doc(widget.userId)
          .collection('medicinehistory')
          .doc(id)
          .update(updatedRecord.toMap());

      // Update local state
      setState(() {
        medicalRecords[index] = updatedRecord;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical record updated successfully')),
      );
    } catch (e) {
      print('Error updating medical record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update medical record')),
      );
    }
  }

  // Delete a record
  Future<void> _deleteRecord(String id) async {
    try {
      // Delete from Firestore
      await _firestore
          .collection('userdata')
          .doc(widget.userId)
          .collection('medicinehistory')
          .doc(id)
          .delete();

      // Update local state
      setState(() {
        medicalRecords.removeWhere((record) => record.id == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical record deleted successfully')),
      );
    } catch (e) {
      print('Error deleting medical record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete medical record')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMedicalRecords,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medical Record',
                    style: FontStyles.heading,
                  ),
                  // Add button
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _showAddMedicalRecordPopup,
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text('Add',
                          style: TextStyle(color: Colors.black)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        side: const BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Medical records list
              Expanded(
                child: medicalRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.note_alt_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No medical records',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _showAddMedicalRecordPopup,
                              child: const Text('Add your first record'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: medicalRecords.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return _buildMedicalRecordItem(medicalRecords[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a medical record list item
  Widget _buildMedicalRecordItem(MedicalRecord record) {
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        bool? result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Record'),
            content:
                Text('Are you sure you want to delete "${record.heading}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      onDismissed: (direction) {
        _deleteRecord(record.id);
      },
      child: InkWell(
        onTap: () => _showMedicalHistoryPopup(record),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Record heading
              Text(
                record.heading,
                style: FontStyles.bodyStrong.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Date
              Text(
                record.getFormattedDate(''),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
