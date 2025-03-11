import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _medicationList = [];
  List<Map<String, dynamic>> _medicalHistory = [];
  List<Map<String, dynamic>> _vitalReadings = [];
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeNotifications();
    _loadUserData();
  }

  Future<void> _initializeNotifications() async {
    tz_init.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        // Handle notification tap
        Navigator.pushNamed(context, '/medications');
      },
    );
  }

  Future<void> _scheduleNotification(String medicineName, TimeOfDay time, String dosage) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    final scheduledDateTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_channel',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      _medicationList.length, // Use as ID
      'Medication Reminder',
      'Time to take $medicineName ($dosage)',
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'medication_$medicineName',
    );
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Load basic user profile data
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        // Load medication data
        final medicationsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .orderBy('nextDose')
            .get();
            
        // Load medical history
        final historySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medicalHistory')
            .orderBy('date', descending: true)
            .get();
            
        // Load vital readings (sugar, blood pressure)
        final vitalsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('vitalReadings')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();
        
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _medicationList = medicationsSnapshot.docs
                .map((doc) => {
                      ...doc.data(),
                      'id': doc.id,
                    })
                .toList();
            _medicalHistory = historySnapshot.docs
                .map((doc) => {
                      ...doc.data(),
                      'id': doc.id,
                    })
                .toList();
            _vitalReadings = vitalsSnapshot.docs
                .map((doc) => {
                      ...doc.data(),
                      'id': doc.id,
                    })
                .toList();
            _isLoading = false;
          });
          
          // Schedule notifications for medications
          for (var medication in _medicationList) {
            if (medication['reminderEnabled'] == true) {
              final timeString = medication['reminderTime'] ?? '08:00';
              final timeParts = timeString.split(':');
              final time = TimeOfDay(
                hour: int.parse(timeParts[0]),
                minute: int.parse(timeParts[1]),
              );
              
              await _scheduleNotification(
                medication['name'],
                time,
                medication['dosage'],
              );
            }
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // User not logged in
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      // Navigate to login screen and clear all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _addNewMedication() {
    // Navigate to add medication page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationPage(
          onMedicationAdded: () {
            _loadUserData(); // Reload data after adding
          },
        ),
      ),
    );
  }

  void _addVitalReading() {
    // Navigate to add vital signs page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVitalReadingPage(
          onReadingAdded: () {
            _loadUserData(); // Reload data after adding
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile page
              // Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.medication), text: 'Medications'),
            Tab(icon: Icon(Icons.history), text: 'Medical History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('No profile data available'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildMedicationsTab(),
                    _buildMedicalHistoryTab(),
                  ],
                ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _addNewMedication,
              child: const Icon(Icons.add),
              tooltip: 'Add Medication',
            )
          : _tabController.index == 2
              ? FloatingActionButton(
                  onPressed: _addVitalReading,
                  child: const Icon(Icons.add),
                  tooltip: 'Add Vital Reading',
                )
              : null,
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with avatar
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueGrey[100],
                  child: Text(
                    _userData!['name']?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userData!['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userData!['isAmbulanceDriver'] ? 'Ambulance Driver' : 'User',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          
          // Personal Information Section
          const SectionHeader(title: 'Personal Information'),
          InfoItem(icon: Icons.phone, title: 'Phone', value: _userData!['phoneNumber'] ?? 'Not provided'),
          InfoItem(icon: Icons.person, title: 'Age', value: _userData!['age']?.toString() ?? 'Not provided'),
          InfoItem(icon: Icons.people, title: 'Gender', value: _userData!['gender'] ?? 'Not provided'),
          InfoItem(icon: Icons.height, title: 'Height', value: _userData!['height'] != null ? '${_userData!['height']} cm' : 'Not provided'),
          InfoItem(icon: Icons.line_weight, title: 'Weight', value: _userData!['weight'] != null ? '${_userData!['weight']} kg' : 'Not provided'),
          InfoItem(icon: Icons.bloodtype, title: 'Blood Type', value: _userData!['bloodType'] ?? 'Not provided'),
          
          // Latest vital signs
          if (_vitalReadings.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SectionHeader(title: 'Latest Vital Signs'),
            
            // Show latest blood sugar
            if (_vitalReadings.any((reading) => reading['type'] == 'bloodSugar'))
    InfoItem(
      icon: Icons.water_drop_outlined,
      title: 'Blood Sugar',
      value: '${_vitalReadings.firstWhere((reading) => reading['type'] == 'bloodSugar')['value']} mg/dL (${_formatTimestamp(_vitalReadings.firstWhere((reading) => reading['type'] == 'bloodSugar')['timestamp'])})',
    ),
  
  if (_vitalReadings.any((reading) => reading['type'] == 'bloodPressure'))
    InfoItem(
      icon: Icons.favorite_outline,
      title: 'Blood Pressure',
      value: '${_vitalReadings.firstWhere((reading) => reading['type'] == 'bloodPressure')['systolic']}/${_vitalReadings.firstWhere((reading) => reading['type'] == 'bloodPressure')['diastolic']} mmHg (${_formatTimestamp(_vitalReadings.firstWhere((reading) => reading['type'] == 'bloodPressure')['timestamp'])})',
    ),
            TextButton(
              onPressed: () {
                _tabController.animateTo(2); // Switch to medical history tab
              },
              child: const Text('View All Readings'),
            ),
          ],
          
          // Only show driver information if user is an ambulance driver
          if (_userData!['isAmbulanceDriver'] == true) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SectionHeader(title: 'Driver Information'),
            InfoItem(icon: Icons.card_membership, title: 'Driver License', value: _userData!['driverLicense'] ?? 'Not provided'),
            InfoItem(icon: Icons.directions_car, title: 'Vehicle Registration', value: _userData!['vehicleRegistrationNumber'] ?? 'Not provided'),
            InfoItem(icon: Icons.local_hospital, title: 'Ambulance Type', value: _userData!['ambulanceType'] ?? 'Not provided'),
            
            const SizedBox(height: 16),
            const Text(
              'Equipment Available:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (_userData!['equipment'] != null && (_userData!['equipment'] as List).isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_userData!['equipment'] as List)
                    .map((item) => Chip(
                          label: Text(item),
                          backgroundColor: Colors.blue[100],
                        ))
                    .toList(),
              )
            else
              const Text('No equipment listed'),
          ],
          
          const SizedBox(height: 24),
          const Divider(),
          
          // Emergency Contact Information
          const SectionHeader(title: 'Emergency Contact'),
          InfoItem(
            icon: Icons.contact_phone,
            title: 'Name',
            value: _userData!['emergencyContact']?['name'] ?? 'Not provided',
          ),
          InfoItem(
            icon: Icons.phone_in_talk,
            title: 'Phone',
            value: _userData!['emergencyContact']?['phone'] ?? 'Not provided',
          ),
          InfoItem(
            icon: Icons.people_outline,
            title: 'Relationship',
            value: _userData!['emergencyContact']?['relationship'] ?? 'Not provided',
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          
          // Account Information Section
          const SectionHeader(title: 'Account Information'),
          if (_userData!['createdAt'] != null)
            InfoItem(
              icon: Icons.calendar_today,
              title: 'Account Created',
              value: _formatTimestamp(_userData!['createdAt']),
            ),
          if (_userData!['updatedAt'] != null)
            InfoItem(
              icon: Icons.update,
              title: 'Last Updated',
              value: _formatTimestamp(_userData!['updatedAt']),
            ),
          
          const SizedBox(height: 32),
          
          // Sign out button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab() {
    if (_medicationList.isEmpty) {
      return const Center(
        child: Text(
          'No medications added yet.\nTap + to add a medication.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _medicationList.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final medication = _medicationList[index];
        final nextDose = medication['nextDose'] != null 
            ? (medication['nextDose'] as Timestamp).toDate()
            : null;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      medication['name'] ?? 'Unknown Medication',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (medication['reminderEnabled'] == true)
                      const Icon(Icons.notifications_active, color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Dosage: ${medication['dosage'] ?? 'Not specified'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Instructions: ${medication['instructions'] ?? 'No special instructions'}',
                  style: const TextStyle(fontSize: 16),
                ),
                if (nextDose != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Next dose: ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(nextDose)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: nextDose.isBefore(DateTime.now()) ? Colors.red : Colors.green[700],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Taken'),
                      onPressed: () {
                        // Mark medication as taken, update next dose
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () {
                        // Edit medication
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicalHistoryTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Medical Records'),
              Tab(text: 'Vital Readings'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMedicalRecordsSection(),
                _buildVitalReadingsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordsSection() {
    if (_medicalHistory.isEmpty) {
      return const Center(
        child: Text(
          'No medical history recorded yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _medicalHistory.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final record = _medicalHistory[index];
        final date = record['date'] != null 
            ? (record['date'] as Timestamp).toDate()
            : null;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ExpansionTile(
            title: Text(
              record['condition'] ?? 'Medical Record',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              date != null ? DateFormat('MMM d, yyyy').format(date) : 'Unknown date',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (record['doctor'] != null) ...[
                      const Text('Doctor:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(record['doctor']),
                      const SizedBox(height: 8),
                    ],
                    if (record['facility'] != null) ...[
                      const Text('Facility:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(record['facility']),
                      const SizedBox(height: 8),
                    ],
                    if (record['diagnosis'] != null) ...[
                      const Text('Diagnosis:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(record['diagnosis']),
                      const SizedBox(height: 8),
                    ],
                    if (record['treatment'] != null) ...[
                      const Text('Treatment:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(record['treatment']),
                      const SizedBox(height: 8),
                    ],
                    if (record['notes'] != null) ...[
                      const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(record['notes']),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVitalReadingsSection() {
    if (_vitalReadings.isEmpty) {
      return const Center(
        child: Text(
          'No vital readings recorded yet.\nTap + to add readings.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    
    // Group readings by type
    final bloodSugarReadings = _vitalReadings.where((r) => r['type'] == 'bloodSugar').toList();
    final bloodPressureReadings = _vitalReadings.where((r) => r['type'] == 'bloodPressure').toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blood Sugar Readings
          if (bloodSugarReadings.isNotEmpty) ...[
            const SectionHeader(title: 'Blood Sugar Readings'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var reading in bloodSugarReadings.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTimestamp(reading['timestamp']),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${reading['value']} mg/dL',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getBloodSugarColor(reading['value']),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Blood Pressure Readings
          if (bloodPressureReadings.isNotEmpty) ...[
            const SectionHeader(title: 'Blood Pressure Readings'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var reading in bloodPressureReadings.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTimestamp(reading['timestamp']),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${reading['systolic']}/${reading['diastolic']} mmHg',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getBloodPressureColor(reading['systolic'], reading['diastolic']),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: const Text('View Health Trends'),
              onPressed: () {
                // Navigate to detailed health trends page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HealthTrendsPage(vitalReadings: _vitalReadings),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getBloodSugarColor(num value) {
    if (value < 70) return Colors.red; // Low
    if (value > 180) return Colors.orange; // High
    return Colors.green; // Normal
  }

  Color _getBloodPressureColor(num systolic, num diastolic) {
    if (systolic >= 180 || diastolic >= 120) return Colors.deepPurple; // Hypertensive Crisis
    if (systolic >= 140 || diastolic >= 90) return Colors.red; // High (Stage 2)
    if (systolic >= 130 || diastolic >= 80) return Colors.orange; // High (Stage 1)
    if (systolic >= 120 && systolic < 130 && diastolic < 80) return Colors.yellow[700]!; // Elevated
    if (systolic < 90 || diastolic < 60) return Colors.blue; // Low
    return Colors.green; // Normal
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
    }
    return 'Unknown';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Helper widget for section headers
class SectionHeader extends StatelessWidget {
  final String title;
  
  const SectionHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Helper widget for info items
class InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const InfoItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add Medication Page
class AddMedicationPage extends StatefulWidget {
  final Function onMedicationAdded;
  
  const AddMedicationPage({Key? key, required this.onMedicationAdded}) : super(key: key);

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g., 10mg, 1 tablet)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                hintText: 'e.g., Take with food, Take before bed',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Enable Reminder'),
              subtitle: const Text('Get notified when it\'s time to take this medication'),
              value: _reminderEnabled,
              onChanged: (value) {
                setState(() {
                  _reminderEnabled = value;
                });
              },
            ),
            if (_reminderEnabled) ...[
              ListTile(
                title: const Text('Reminder Time'),
                subtitle: Text(_reminderTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _reminderTime = pickedTime;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveMedication,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Save Medication'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          // Calculate next dose time based on current time and reminder settings
          DateTime nextDose = DateTime.now();
          if (_reminderEnabled) {
            nextDose = DateTime(
              nextDose.year,
              nextDose.month,
              nextDose.day,
              _reminderTime.hour,
              _reminderTime.minute,
            );
            // If current time is after reminder time, schedule for next day
            if (nextDose.isBefore(DateTime.now())) {
              nextDose = nextDose.add(const Duration(days: 1));
            }
          }
          
          await _firestore.collection('users').doc(user.uid).collection('medications').add({
            'name': _nameController.text,
            'dosage': _dosageController.text,
            'instructions': _instructionsController.text,
            'reminderEnabled': _reminderEnabled,
            'reminderTime': '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
            'nextDose': Timestamp.fromDate(nextDose),
            'createdAt': Timestamp.now(),
          });
          
          widget.onMedicationAdded();
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medication added successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding medication: $e')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}

// Add Vital Reading Page
class AddVitalReadingPage extends StatefulWidget {
  final Function onReadingAdded;
  
  const AddVitalReadingPage({Key? key, required this.onReadingAdded}) : super(key: key);

  @override
  State<AddVitalReadingPage> createState() => _AddVitalReadingPageState();
}

class _AddVitalReadingPageState extends State<AddVitalReadingPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'bloodSugar'; // Default to blood sugar
  final _bloodSugarController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _readingDate = DateTime.now();
  TimeOfDay _readingTime = TimeOfDay.now();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vital Reading'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Reading Type',
                border: OutlineInputBorder(),
              ),
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'bloodSugar', child: Text('Blood Sugar')),
                DropdownMenuItem(value: 'bloodPressure', child: Text('Blood Pressure')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Show fields based on selected type
            if (_selectedType == 'bloodSugar') ...[
              TextFormField(
                controller: _bloodSugarController,
                decoration: const InputDecoration(
                  labelText: 'Blood Sugar (mg/dL)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter blood sugar value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ] else if (_selectedType == 'bloodPressure') ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _systolicController,
                      decoration: const InputDecoration(
                        labelText: 'Systolic (mmHg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _diastolicController,
                      decoration: const InputDecoration(
                        labelText: 'Diastolic (mmHg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Reading Date'),
              subtitle: Text(DateFormat('MMM d, yyyy').format(_readingDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _readingDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() {
                    _readingDate = pickedDate;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('Reading Time'),
              subtitle: Text(_readingTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: _readingTime,
                );
                if (pickedTime != null) {
                  setState(() {
                    _readingTime = pickedTime;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional: any additional information',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveVitalReading,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Save Reading'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveVitalReading() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          // Combine date and time into a single DateTime
          final timestamp = DateTime(
            _readingDate.year,
            _readingDate.month,
            _readingDate.day,
            _readingTime.hour,
            _readingTime.minute,
          );
          
          final data = {
            'type': _selectedType,
            'timestamp': Timestamp.fromDate(timestamp),
            'notes': _notesController.text.trim(),
          };
          
          // Add type-specific fields
          if (_selectedType == 'bloodSugar') {
            data['value'] = double.parse(_bloodSugarController.text);
          } else if (_selectedType == 'bloodPressure') {
            data['systolic'] = int.parse(_systolicController.text);
            data['diastolic'] = int.parse(_diastolicController.text);
          }
          
          await _firestore.collection('users').doc(user.uid).collection('vitalReadings').add(data);
          
          widget.onReadingAdded();
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vital reading saved successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reading: $e')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _bloodSugarController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

// Health Trends Page
class HealthTrendsPage extends StatelessWidget {
  final List<Map<String, dynamic>> vitalReadings;
  
  const HealthTrendsPage({Key? key, required this.vitalReadings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Process data for charts
    final bloodSugarReadings = vitalReadings
        .where((r) => r['type'] == 'bloodSugar')
        .map((r) => {
          'date': (r['timestamp'] as Timestamp).toDate(),
          'value': r['value'],
        })
        .toList()
        ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final bloodPressureReadings = vitalReadings
        .where((r) => r['type'] == 'bloodPressure')
        .map((r) => {
          'date': (r['timestamp'] as Timestamp).toDate(),
          'systolic': r['systolic'],
          'diastolic': r['diastolic'],
        })
        .toList()
        ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Trends'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats overview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatCard(
                          context,
                          'Blood Sugar',
                          bloodSugarReadings.isNotEmpty
                              ? '${_calculateAverage(bloodSugarReadings.map((r) => r['value'] as num).toList()).toStringAsFixed(1)} mg/dL'
                              : 'No data',
                          Icons.water_drop_outlined,
                          Colors.blue[100]!,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          context,
                          'Blood Pressure',
                          bloodPressureReadings.isNotEmpty
                              ? '${_calculateAverage(bloodPressureReadings.map((r) => r['systolic'] as num).toList()).toStringAsFixed(0)}/${_calculateAverage(bloodPressureReadings.map((r) => r['diastolic'] as num).toList()).toStringAsFixed(0)}'
                              : 'No data',
                          Icons.favorite_outline,
                          Colors.red[100]!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Blood Sugar Chart
            if (bloodSugarReadings.isNotEmpty) ...[
              const Text(
                'Blood Sugar Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildBloodSugarChart(bloodSugarReadings),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Blood Pressure Chart
            if (bloodPressureReadings.isNotEmpty) ...[
              const Text(
                'Blood Pressure Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildBloodPressureChart(bloodPressureReadings),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Recommendations based on readings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Recommendations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• Remember to take your measurements consistently for better tracking',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Share this data with your healthcare provider at your next visit',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    
                    // Blood sugar specific recommendations
                    if (bloodSugarReadings.isNotEmpty) ...[
                      Text(
                        _getBloodSugarRecommendation(bloodSugarReadings),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Blood pressure specific recommendations
                    if (bloodPressureReadings.isNotEmpty) ...[
                      Text(
                        _getBloodPressureRecommendation(bloodPressureReadings),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodSugarChart(List<Map<String, dynamic>> data) {
    // This is a placeholder for actual chart implementation
    // In a real app, you would use a charting library like charts_flutter or fl_chart
    return Center(
      child: Text(
        'Blood Sugar Chart Placeholder\n${data.length} readings available',
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBloodPressureChart(List<Map<String, dynamic>> data) {
    // This is a placeholder for actual chart implementation
    return Center(
      child: Text(
        'Blood Pressure Chart Placeholder\n${data.length} readings available',
        textAlign: TextAlign.center,
      ),
    );
  }

  double _calculateAverage(List<num> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _getBloodSugarRecommendation(List<Map<String, dynamic>> readings) {
    final avgValue = _calculateAverage(readings.map((r) => r['value'] as num).toList());
    
    if (avgValue > 180) {
      return '• Your average blood sugar is high. Consider discussing medication adjustments with your doctor.';
    } else if (avgValue > 140) {
      return '• Your average blood sugar is slightly elevated. Monitor your carbohydrate intake.';
    } else if (avgValue < 70) {
      return '• Your average blood sugar is low. Consider carrying fast-acting glucose with you.';
    } else {
      return '• Your average blood sugar is within normal range. Keep up the good work!';
    }
  }

  String _getBloodPressureRecommendation(List<Map<String, dynamic>> readings) {
    final avgSystolic = _calculateAverage(readings.map((r) => r['systolic'] as num).toList());
    final avgDiastolic = _calculateAverage(readings.map((r) => r['diastolic'] as num).toList());
    
    if (avgSystolic >= 140 || avgDiastolic >= 90) {
      return '• Your average blood pressure is high. Consider reducing sodium intake and stress levels.';
    } else if (avgSystolic >= 120 || avgDiastolic >= 80) {
      return '• Your average blood pressure is slightly elevated. Regular exercise may help reduce it.';
    } else if (avgSystolic < 90 || avgDiastolic < 60) {
      return '• Your average blood pressure is low. Stay well-hydrated and stand up slowly.';
    } else {
      return '• Your average blood pressure is within normal range. Maintain your healthy habits!';
    }
  }
}