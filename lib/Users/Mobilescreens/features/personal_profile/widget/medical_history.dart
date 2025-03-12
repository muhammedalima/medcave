import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>> medicalHistory = [];
  Stream<QuerySnapshot>? _medicalHistoryStream;

  // Text controllers for the dialog
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _medicineNameController = TextEditingController();
  
  // Selected date for the medicine
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Set up real-time stream instead of one-time fetch
    _setupMedicalHistoryStream();
    
    // Add a delay and refetch to ensure data is loaded (for development purposes)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _debugFirestoreConnection();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _medicineNameController.dispose();
    super.dispose();
  }

  void _setupMedicalHistoryStream() {
    if (widget.userId.isNotEmpty) {
      // Create a stream that updates in real-time with proper error handling
      try {
        _medicalHistoryStream = _firestore
            .collection('medicalHistory')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('date', descending: true)
            .snapshots()
            .handleError((error) {
              if (kDebugMode) {
                print('Error in stream: $error');
              }
              // Update UI to show error state
              if (mounted) {
                setState(() {
                  isLoading = false;
                });
              }
            });
        
        if (kDebugMode) {
          print('Medical history stream setup for user: ${widget.userId}');
        }
        
        // This will trigger a rebuild of the UI when data changes
        setState(() {
          isLoading = false;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error setting up stream: $e');
        }
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (kDebugMode) {
        print('Error: userId is empty');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToMedicalHistoryDetail(Map<String, dynamic> record) {
    // Navigate to detail view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record['title'] ?? 'Medical Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description section
              if (record['description'] != null && record['description'].toString().isNotEmpty) ...[
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(record['description'].toString()),
                const SizedBox(height: 16),
              ],
              
              // Medicine section
              const Text('Medicine:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.medication, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record['medicineName'] != null && record['medicineName'].toString().isNotEmpty
                          ? record['medicineName'].toString()
                          : 'No medicine specified',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date section
              const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    record['date'] != null
                        ? DateFormat('yyyy-MM-dd').format((record['date'] as Timestamp).toDate())
                        : 'No date specified',
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditMedicalRecordDialog(record);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              _deleteMedicalRecord(record['id']);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Function to delete a medical record
  Future<void> _deleteMedicalRecord(String recordId) async {
    try {
      await _firestore.collection('medicalHistory').doc(recordId).delete();
      
      if (kDebugMode) {
        print('Medical record deleted successfully: $recordId');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical record deleted successfully')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting medical record: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete medical record: $e')),
        );
      }
    }
  }

  // Show dialog to edit an existing medical record
  void _showEditMedicalRecordDialog(Map<String, dynamic> record) {
    // Set controllers with existing data
    _titleController.text = record['title'] ?? '';
    _descriptionController.text = record['description'] ?? '';
    _medicineNameController.text = record['medicineName'] ?? '';
    
    // Set selected date from record
    if (record['date'] != null) {
      _selectedDate = (record['date'] as Timestamp).toDate();
    } else {
      _selectedDate = DateTime.now();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Medical Record'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _medicineNameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Date: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          
                          if (picked != null && picked != _selectedDate) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Select Date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _updateMedicalRecord(record['id']);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        }
      ),
    );
  }

  // Update an existing medical record
  Future<void> _updateMedicalRecord(String recordId) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    
    try {
      final Map<String, dynamic> recordData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'medicineName': _medicineNameController.text,
        'date': Timestamp.fromDate(_selectedDate),
        'updatedAt': Timestamp.now(),
      };
      
      await _firestore
          .collection('medicalHistory')
          .doc(recordId)
          .update(recordData);
      
      if (kDebugMode) {
        print('Medical record updated successfully: $recordId');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical record updated successfully')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating medical record: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update medical record: $e')),
        );
      }
    }
  }

  // Function to pick a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (kDebugMode) {
        print('Selected date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
      }
    }
  }

  // Show dialog to add a new medical record
  void _showAddMedicalRecordDialog() {
    // Reset controllers
    _titleController.clear();
    _descriptionController.clear();
    _medicineNameController.clear();
    _selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Medical Record'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Medicine name field
                  TextField(
                    controller: _medicineNameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date picker button
                  Row(
                    children: [
                      const Text('Date: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          
                          if (picked != null && picked != _selectedDate) {
                            setState(() {
                              _selectedDate = picked;
                            });
                            if (kDebugMode) {
                              print('Dialog selected date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
                            }
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Select Date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (kDebugMode) {
                    print('Medicine name before save: ${_medicineNameController.text}');
                    print('Selected date before save: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
                  }
                  await _addNewMedicalRecord();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }

  // Add a new medical record to Firestore
  Future<void> _addNewMedicalRecord() async {
    if (_titleController.text.isEmpty) {
      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    
    try {
      // Prepare data map
      final Map<String, dynamic> recordData = {
        'userId': widget.userId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'medicineName': _medicineNameController.text,
        'date': Timestamp.fromDate(_selectedDate),
        'createdAt': Timestamp.now(),
      };

      if (kDebugMode) {
        print('Saving record with data:');
        recordData.forEach((key, value) {
          if (kDebugMode) {
            print('$key: $value');
          }
        });
      }
      
      // Add the record to Firestore
      DocumentReference docRef = await _firestore
          .collection('medicalHistory')
          .add(recordData);
      
      if (kDebugMode) {
        print('Medical record added successfully with ID: ${docRef.id}');
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical record added successfully')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding medical record: $e');
      }
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add medical record: $e')),
        );
      }
    }
  }

  // Debug method to check Firestore connection with enhanced error handling
  Future<void> _debugFirestoreConnection() async {
    try {
      if (kDebugMode) {
        print('Testing Firestore connection...');
        print('User ID: ${widget.userId}');
      }
      
      // Try to get a count of documents
      final QuerySnapshot snapshot = await _firestore
          .collection('medicalHistory')
          .where('userId', isEqualTo: widget.userId)
          .get();
      
      if (kDebugMode) {
        print('Firestore connection successful');
        print('Found ${snapshot.docs.length} documents');
        
        // Print all documents for debugging
        if (snapshot.docs.isNotEmpty) {
          print('Document data:');
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            print('Document ID: ${doc.id}');
            data.forEach((key, value) {
              if (kDebugMode) {
                print('$key: $value');
              }
            });
            print('---------------');
          }
        } else {
          print('No documents found. This may be normal if no records have been added yet.');
          // Add a test record for development if needed
          /*
          await _firestore.collection('medicalHistory').add({
            'userId': widget.userId,
            'title': 'Test Record',
            'description': 'This is a test record',
            'medicineName': 'Test Medicine',
            'date': Timestamp.now(),
            'createdAt': Timestamp.now(),
          });
          print('Test record added for development purposes');
          */
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found ${snapshot.docs.length} records')),
      );
      
      // Refresh UI after debug check
      setState(() {});
      
    } catch (e) {
      if (kDebugMode) {
        print('Firestore connection error: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore error: $e')),
      );
    }
  }

  // Show loading indicator
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading medical records...')
        ],
      ),
    );
  }

  // Create a card widget for a medical record
  Widget _buildMedicalRecordCard(Map<String, dynamic> record) {
    // Format the date with enhanced debugging
    String formattedDate = '';
    if (record['date'] != null) {
      try {
        final date = (record['date'] as Timestamp).toDate();
        formattedDate = DateFormat('yyyy-MM-dd').format(date);
      } catch (e) {
        if (kDebugMode) {
          print('Record ${record['id']} - Error formatting date: $e');
        }
        formattedDate = 'Invalid date';
      }
    } else {
      formattedDate = 'No date';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToMedicalHistoryDetail(record),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      record['title'] ?? 'Medical Record',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              if (record['description'] != null && record['description'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text(
                    record['description'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),
                
              const SizedBox(height: 8),
              
              // Medicine name with icon
              Row(
                children: [
                  const Icon(Icons.medication, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record['medicineName'] != null && record['medicineName'].toString().isNotEmpty
                          ? record['medicineName'].toString()
                          : 'No medicine specified',
                      style: TextStyle(
                        color: record['medicineName'] != null && record['medicineName'].toString().isNotEmpty
                            ? Colors.blue[700]
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => _navigateToMedicalHistoryDetail(record),
                    splashRadius: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to display when there are no records
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No medical records yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your medical history to keep track of your health',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _showAddMedicalRecordDialog,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Add Medical Record'),
          ),
        ],
      ),
    );
  }

  // Search medical records
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: 'Search medical records',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          // Implement search functionality
          if (kDebugMode) {
            print('Search query: $value');
          }
          // This would filter the stream results
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if userId is valid
    if (widget.userId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Invalid user ID',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Please ensure you are logged in properly'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Current user ID: ${widget.userId}')),
                );
              },
              child: const Text('Check User ID'),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return _buildLoadingIndicator();
    }

    // Using StreamBuilder to automatically update UI when Firestore data changes
    return StreamBuilder<QuerySnapshot>(
      stream: _medicalHistoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading medical records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _debugFirestoreConnection,
                  child: const Text('Check Firestore Connection'),
                ),
              ],
            ),
          );
        }

        // Convert the snapshot to a list of records
        List<Map<String, dynamic>> medicalRecords = [];
        if (snapshot.hasData) {
          medicalRecords = snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
          
          if (kDebugMode) {
            print('Loaded ${medicalRecords.length} medical records from stream');
          }
        }

        // Return the main UI structure based on data availability
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header and Add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Medical Records',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddMedicalRecordDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              
              // Search bar for filtering records
              _buildSearchBar(),
              
              // Record count and debug button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${medicalRecords.length} records found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _debugFirestoreConnection,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              
              // Main content - either list of records or empty state
              Expanded(
                child: medicalRecords.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _debugFirestoreConnection();
                        },
                        child: ListView.builder(
                          itemCount: medicalRecords.length,
                          itemBuilder: (context, index) {
                            final record = medicalRecords[index];
                            return _buildMedicalRecordCard(record);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}