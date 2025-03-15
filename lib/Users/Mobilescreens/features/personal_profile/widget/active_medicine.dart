import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medcave/common/database/User/medicine/user_medicine.dart';
import 'package:medcave/config/fonts/font.dart';

class ActiveMedicinesSection extends StatefulWidget {
  final List<Medicine> medicines;
  final VoidCallback onAddPressed;

  const ActiveMedicinesSection({
    Key? key,
    required this.medicines,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  State<ActiveMedicinesSection> createState() => _ActiveMedicinesSectionState();
}

class _ActiveMedicinesSectionState extends State<ActiveMedicinesSection> {
  // Map to track notification state for each medicine
  Map<String, bool> notificationStates = {};

  @override
  void initState() {
    super.initState();
    // Initialize notifications as active for all medicines
    for (var medicine in widget.medicines) {
      notificationStates[medicine.id] = true;
    }
  }

  // Toggle notification state for a specific medicine
  void _toggleNotification(String medicineId) {
    setState(() {
      notificationStates[medicineId] = !(notificationStates[medicineId] ?? true);
    });
    
    // Here you would typically update this in your database
    // For example: updateMedicineNotificationState(medicineId, notificationStates[medicineId]);
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
            // Updated Add button to match UI
            OutlinedButton.icon(
              onPressed: widget.onAddPressed,
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
                  return _buildActiveMedicineItem(widget.medicines[index]);
                },
              ),
      ],
    );
  }

  Widget _buildActiveMedicineItem(Medicine medicine) {
    // Get notification state for this medicine (default to true if not found)
    final isNotificationActive = notificationStates[medicine.id] ?? true;
    
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
                        _formatSchedule(medicine.schedule) + 
                        " - " + 
                        _formatCourseEnd(medicine.endDate),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
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
        ],
      ),
    );
  }

  // Helper to format schedule list as "morning / noon / night"
  String _formatSchedule(List<String> schedule) {
    if (schedule.isEmpty) return "";
    
    return schedule.map((time) {
      // Convert to lowercase to match the UI
      return time.toLowerCase();
    }).join(" / ");
  }
}