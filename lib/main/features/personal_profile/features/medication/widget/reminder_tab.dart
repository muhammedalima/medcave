import 'package:flutter/material.dart';
import 'package:medcave/common/database/model/User/reminder/reminder_db.dart';
import 'package:medcave/config/colors/appcolor.dart';

class ReminderTimeSection extends StatelessWidget {
  final ReminderModel reminderData;
  final Function(String type, String mealTime, TimeOfDay time) onTimeChanged;

  const ReminderTimeSection({
    Key? key,
    required this.reminderData,
    required this.onTimeChanged,
  }) : super(key: key);

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Set time';

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Show dialog to edit both before and after food times
  Future<void> _showEditDialog(BuildContext context, String type) async {
    TimeOfDay? beforeFoodTime;
    TimeOfDay? afterFoodTime;
    String title;
    IconData icon;

    // Set initial values based on type
    if (type == 'morning') {
      title = 'Morning';
      icon = Icons.wb_sunny;
      beforeFoodTime = reminderData.morningBeforeFood;
      afterFoodTime = reminderData.morningAfterFood;
    } else if (type == 'noon') {
      title = 'Noon';
      icon = Icons.wb_twilight;
      beforeFoodTime = reminderData.noonBeforeFood;
      afterFoodTime = reminderData.noonAfterFood;
    } else {
      // night
      title = 'Night';
      icon = Icons.nightlight_round;
      beforeFoodTime = reminderData.nightBeforeFood;
      afterFoodTime = reminderData.nightAfterFood;
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Column(
                children: [
                  Text('Reminder Times'),
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: type == 'morning'
                            ? Colors.orange
                            : type == 'noon'
                                ? Colors.black
                                : Colors.indigo[900],
                      ),
                      const SizedBox(width: 8),
                      Text(title),
                    ],
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Before food time selector
                  ListTile(
                    title: const Text('Before Food'),
                    trailing: Text(
                      _formatTimeOfDay(beforeFoodTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final TimeOfDay? result = await showTimePicker(
                        context: context,
                        initialTime: beforeFoodTime ?? TimeOfDay.now(),
                      );
                      if (result != null) {
                        setState(() {
                          beforeFoodTime = result;
                        });
                      }
                    },
                  ),

                  // After food time selector
                  ListTile(
                    title: const Text('After Food'),
                    trailing: Text(
                      _formatTimeOfDay(afterFoodTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final TimeOfDay? result = await showTimePicker(
                        context: context,
                        initialTime: afterFoodTime ?? TimeOfDay.now(),
                      );
                      if (result != null) {
                        setState(() {
                          afterFoodTime = result;
                        });
                      }
                    },
                  ),
                ],
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
                    // Save both times
                    if (beforeFoodTime != null) {
                      onTimeChanged(type, 'beforeFood', beforeFoodTime!);
                    }
                    if (afterFoodTime != null) {
                      onTimeChanged(type, 'afterFood', afterFoodTime!);
                    }
                    Navigator.of(context).pop();
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

  Widget _buildReminderItem(
    BuildContext context,
    String type,
    IconData icon,
  ) {
    TimeOfDay? beforeFoodTime;
    TimeOfDay? afterFoodTime;

    // Set values based on type
    if (type == 'morning') {
      beforeFoodTime = reminderData.morningBeforeFood;
      afterFoodTime = reminderData.morningAfterFood;
    } else if (type == 'noon') {
      beforeFoodTime = reminderData.noonBeforeFood;
      afterFoodTime = reminderData.noonAfterFood;
    } else {
      // night
      beforeFoodTime = reminderData.nightBeforeFood;
      afterFoodTime = reminderData.nightAfterFood;
    }

    return GestureDetector(
      onTap: () => _showEditDialog(context, type),
      child: Container(
        padding: EdgeInsets.all(4),
        color: AppColor.backgroundWhite,
        margin: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Before food time
            Text(
              _formatTimeOfDay(beforeFoodTime),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Icon
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                icon,
                size: 24,
                color: type == 'morning'
                    ? Colors.orange
                    : type == 'noon'
                        ? Colors.black
                        : Colors.indigo[900],
              ),
            ),

            // After food time
            Text(
              _formatTimeOfDay(afterFoodTime),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildReminderItem(context, 'morning', Icons.wb_sunny),
              _buildReminderItem(context, 'noon', Icons.wb_twilight),
              _buildReminderItem(context, 'night', Icons.nightlight_round),
            ],
          ),
        ),
      ),
    );
  }
}
