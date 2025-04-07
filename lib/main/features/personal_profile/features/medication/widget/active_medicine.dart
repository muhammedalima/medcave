import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medcave/main/features/personal_profile/features/medication/widget/add_medicine_popup.dart';
import 'package:medcave/common/database/model/User/medicine/user_medicine_db.dart';
import 'package:medcave/config/fonts/font.dart';

class ActiveMedicinesSection extends StatefulWidget {
  final List<Medicine> medicines;
  final VoidCallback? onAddPressed; // Optional for backward compatibility
  final Function(String, bool)? onNotificationToggled; // Optional callback to update notification
  final Function(String)? onMedicineDeleted; // New callback for medicine deletion

  const ActiveMedicinesSection({
    Key? key,
    required this.medicines,
    this.onAddPressed,
    this.onNotificationToggled,
    this.onMedicineDeleted,
  }) : super(key: key);

  @override
  State<ActiveMedicinesSection> createState() => _ActiveMedicinesSectionState();
}

class _ActiveMedicinesSectionState extends State<ActiveMedicinesSection> {
  // Map to track notification state for each medicine (for local updates)
  Map<String, bool> notificationStates = {};

  @override
  void initState() {
    super.initState();
    // Initialize notifications based on medicine data
    _initializeNotificationStates();
  }

  @override
  void didUpdateWidget(ActiveMedicinesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize if medicines list changed
    if (oldWidget.medicines != widget.medicines) {
      _initializeNotificationStates();
    }
  }

  // Initialize notifications based on medicine data
  void _initializeNotificationStates() {
    for (var medicine in widget.medicines) {
      notificationStates[medicine.id] = medicine.notify;
    }
  }

  // Toggle notification state for a specific medicine
  void _toggleNotification(String medicineId) {
    final newState = !(notificationStates[medicineId] ?? true);
    
    setState(() {
      notificationStates[medicineId] = newState;
    });

    // Update in database if callback is provided
    if (widget.onNotificationToggled != null) {
      widget.onNotificationToggled!(medicineId, newState);
    }
  }

  // Delete a medicine from the database
  void _deleteMedicine(String medicineId) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Call the delete callback if provided
              if (widget.onMedicineDeleted != null) {
                widget.onMedicineDeleted!(medicineId);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Show the add medication popup
  void _showAddOptions() {
    if (widget.onAddPressed != null) {
      widget.onAddPressed!();
    } else {
      // Default behavior if no callback provided
      showAddMedicationPopup(context);
    }
  }

  String _formatCourseEnd(DateTime? endDate) {
    if (endDate == null) return "";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final endDateCompare = DateTime(endDate.year, endDate.month, endDate.day);

    if (endDateCompare.isAtSameMomentAs(today)) {
      return "course ends today";
    } else if (endDateCompare.isAtSameMomentAs(tomorrow)) {
      return "course ends tomorrow";
    } else {
      return "course ends ${DateFormat('dd MMM yyyy').format(endDate)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with "Active Medicine" and "Add" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Medicine',
              style: FontStyles.heading,
            ),
            // Add button to show popup
            OutlinedButton.icon(
              onPressed: _showAddOptions,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Add', style: TextStyle(color: Colors.black)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                side: const BorderSide(color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Medicine list
        widget.medicines.isEmpty
            ? const Text('No active medicines')
            : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: widget.medicines.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _buildDismissibleMedicineItem(widget.medicines[index]);
                },
              ),
      ],
    );
  }

  // Build a dismissible medicine item (swipe to delete)
  Widget _buildDismissibleMedicineItem(Medicine medicine) {
    return Dismissible(
      key: Key(medicine.id),
      direction: DismissDirection.endToStart, // Only allow right to left swipe
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
            title: const Text('Delete Medicine'),
            content: Text('Are you sure you want to delete ${medicine.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      onDismissed: (direction) {
        if (widget.onMedicineDeleted != null) {
          widget.onMedicineDeleted!(medicine.id);
        }
      },
      child: _buildActiveMedicineItem(medicine),
    );
  }

  Widget _buildActiveMedicineItem(Medicine medicine) {
    // Get notification state - prefer the local state if available, otherwise use the medicine's state
    final isNotificationActive = notificationStates[medicine.id] ?? medicine.notify;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Medicine info (left side)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine name
                Text(
                  medicine.name,
                  style: FontStyles.bodyStrong.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Schedule and end date
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatSchedule(medicine) +
                            " - " +
                            _formatCourseEnd(medicine.endDate),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notification bell (right side) - now clickable to toggle
          GestureDetector(
            onTap: () => _toggleNotification(medicine.id),
            child: Container(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                isNotificationActive
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: isNotificationActive ? Colors.black : Colors.grey,
                size: 32,
              ),
            ),
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
    );
  }

  // Helper to format schedule for a medicine (morning / noon / night)
  String _formatSchedule(Medicine medicine) {
    List<String> parts = [];
    if (medicine.morning) parts.add("morning");
    if (medicine.afternoon) parts.add("noon");
    if (medicine.evening) parts.add("night");
    return parts.join(" / ");
  }
}