import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/active_medicine.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/add_medicine_popup.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/past_medicine_list.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/widget/reminder_tab.dart';
import 'package:medcave/common/database/model/User/medicine/user_medicine_db.dart';
import 'package:medcave/common/database/model/User/reminder/reminder_db.dart';
import 'package:medcave/common/database/service/medcine_services.dart';

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
  List<Medicine> activeMedicines = [];
  List<Medicine> pastMedicines = [];
  bool isLoading = true;
  bool isRefreshing = false;
  late ReminderDatabase _reminderDatabase;
  late ReminderModel _reminderData;

  // Refresh controller
  final RefreshIndicatorMode _refreshIndicatorMode = RefreshIndicatorMode.drag;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Initialize the medicine service
  final MedicineService _medicineService = MedicineService();

  @override
  void initState() {
    super.initState();
    _reminderDatabase = ReminderDatabase();
    _loadMedicinesAndReminders();
  }

  Future<void> _loadMedicinesAndReminders() async {
    try {
      if (!isRefreshing) {
        setState(() {
          isLoading = true;
        });
      }

      // Load reminder data
      await _loadReminderData();

      // Load medicines data from Firebase
      await _loadMedicinesFromFirebase();

      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error in _loadMedicinesAndReminders: $e');
      }
      setState(() {
        isLoading = false;
        isRefreshing = false;
        // If loading fails, use dummy data as fallback
        _loadDummyMedicines();
      });
    }
  }

  // Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    setState(() {
      isRefreshing = true;
    });

    if (kDebugMode) {
      print('Refreshing medication data...');
    }

    // Load fresh data
    await _loadMedicinesFromFirebase();

    // Return a delayed future to show the refresh indicator for a minimum time
    return await Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        isRefreshing = false;
      });
    });
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
          morningBeforeFood: _reminderData.morningBeforeFood ??
              const TimeOfDay(hour: 7, minute: 30),
          morningAfterFood: _reminderData.morningAfterFood ??
              const TimeOfDay(hour: 9, minute: 0),
          noonBeforeFood: _reminderData.noonBeforeFood ??
              const TimeOfDay(hour: 12, minute: 30),
          noonAfterFood: _reminderData.noonAfterFood ??
              const TimeOfDay(hour: 14, minute: 0),
          nightBeforeFood: _reminderData.nightBeforeFood ??
              const TimeOfDay(hour: 19, minute: 30),
          nightAfterFood: _reminderData.nightAfterFood ??
              const TimeOfDay(hour: 21, minute: 0),
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

  // Load medicines from Firebase
  Future<void> _loadMedicinesFromFirebase() async {
    try {
      List<Medicine> medicines = [];

      // Get medicines for the specific user
      if (widget.userId.isNotEmpty) {
        // Use the extension method to get medicines for the user
        medicines = await _medicineService.getMedicinesForUser(widget.userId);
      } else {
        // If no user ID, try to get medicines for the current user
        medicines = await _medicineService.getMedicinesAsList();
      }

      // If no medicines found, use dummy data as fallback
      if (medicines.isEmpty) {
        if (kDebugMode) {
          print('No medicines found, using dummy data');
        }
        _loadDummyMedicines();
        setState(() {
          isLoading = false; // Ensure loading state is turned off
          isRefreshing = false;
        });
        return;
      }

      // Categorize medicines as active or past based on end date
      final DateTime today = DateTime.now();
      // Set to midnight for date comparison
      final DateTime todayStart = DateTime(today.year, today.month, today.day);

      List<Medicine> active = [];
      List<Medicine> past = [];

      for (var medicine in medicines) {
        // Compare dates only (not time)
        final DateTime endDate = DateTime(medicine.endDate.year,
            medicine.endDate.month, medicine.endDate.day);

        if (endDate.isAfter(todayStart) ||
            endDate.isAtSameMomentAs(todayStart)) {
          active.add(medicine);
        } else {
          past.add(medicine);
        }
      }

      if (kDebugMode) {
        print(
            'Loaded ${active.length} active medicines and ${past.length} past medicines from Firebase');
      }

      setState(() {
        activeMedicines = active;
        pastMedicines = past;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading medicines from Firebase: $e');
      }

      // Fall back to dummy data on error
      _loadDummyMedicines();
      setState(() {
        isLoading = false; // Ensure loading state is turned off on error
        isRefreshing = false;
      });
    }
  }

  Future<void> _updateReminderTime(
      String type, String mealTime, TimeOfDay time) async {
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

  // Update notification setting for a medicine in Firestore
  Future<void> _updateMedicineNotification(
      String medicineId, bool notify) async {
    try {
      await _medicineService.updateMedicineNotification(medicineId, notify);

      // After successful update, refresh medicines
      await _loadMedicinesFromFirebase();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating medicine notification: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update notification: $e')),
      );
    }
  }

  // Delete a medicine from Firestore
  Future<void> _deleteMedicine(String medicineId) async {
    try {
      setState(() {
        isLoading = true;
      });

      // Delete from Firestore
      await _medicineService.deleteMedicine(medicineId);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine deleted successfully')),
      );

      // Reload medicines to refresh the UI
      await _loadMedicinesFromFirebase();

      // Ensure loading state is turned off
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting medicine: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete medicine: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // Load dummy medicines for testing or as fallback
  void _loadDummyMedicines() {
    if (kDebugMode) {
      print('Loading dummy medicine data');
    }
    // Active medicines (current and future end dates)
    activeMedicines = [
      Medicine(
        id: 'dummy-1',
        name: 'Paracetamol',
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 4)),
        morning: true,
        afternoon: true,
        evening: true,
        notify: true,
      ),
      Medicine(
        id: 'dummy-2',
        name: 'Citrazin',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        morning: false,
        afternoon: false,
        evening: true,
        notify: true,
      ),
      Medicine(
        id: 'dummy-3',
        name: 'Vitamin A',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 20)),
        morning: true,
        afternoon: true,
        evening: false,
        notify: false,
      ),
    ];

    // Past medicines (expired end dates)
    pastMedicines = [
      Medicine(
        id: 'past-1',
        name: 'Amoxicillin',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().subtract(const Duration(days: 23)),
        morning: true,
        afternoon: true,
        evening: true,
        notify: false,
      ),
      Medicine(
        id: 'past-2',
        name: 'Ibuprofen',
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        endDate: DateTime.now().subtract(const Duration(days: 38)),
        morning: true,
        afternoon: false,
        evening: true,
        notify: false,
      ),
    ];
  }

  // Show add medicine popup
  void _showAddOptions() {
    // Show the add medication popup instead of navigating directly
    showAddMedicationPopup(context);
  }

  void _showViewAllPastMedicines() {
    // This function is now handled internally by the PastMedicinesSection widget
    // It will automatically show all medicines when the "view all" button is clicked
    if (kDebugMode) {
      print('Showing all past medicines');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Important for refresh to work when content doesn't fill screen
        child: Column(
          children: [
            // Reminder Time Section
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
                  // Active Medicines Section with delete functionality
                  ActiveMedicinesSection(
                    medicines: activeMedicines,
                    onAddPressed: _showAddOptions,
                    onNotificationToggled: _updateMedicineNotification,
                    onMedicineDeleted: _deleteMedicine,
                  ),

                  const SizedBox(height: 24),

                  // Past Medicines Section with delete functionality
                  PastMedicinesSection(
                    medicines: pastMedicines,
                    onViewAllPressed: _showViewAllPastMedicines,
                    onMedicineDeleted: _deleteMedicine,
                  ),

                  // Bottom padding
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
