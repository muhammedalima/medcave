import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medcave/common/database/model/User/medicine/user_medicine_db.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/config/fonts/font.dart';

class AddNewMedicinePopup extends StatefulWidget {
  final Function(Medicine) onAddMedicine;
  final VoidCallback onClose;

  const AddNewMedicinePopup({
    Key? key,
    required this.onAddMedicine,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AddNewMedicinePopup> createState() => _AddNewMedicinePopupState();
}

class _AddNewMedicinePopupState extends State<AddNewMedicinePopup> {
  final TextEditingController _medicineNameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  bool _morning = false;
  bool _afternoon = false;
  bool _evening = false;
  bool _beforeMeals = false; // New state for before meals
  bool _afterMeals = false; // New state for after meals
  bool _notify = true;

  @override
  void dispose() {
    _medicineNameController.dispose();
    super.dispose();
  }

  // Format date as "DD-MM-YYYY"
  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  // Select date using date picker - modified to allow past dates
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    // Allow selecting dates from 1 year ago for recording past medicines
    final DateTime oneYearAgo =
        DateTime.now().subtract(const Duration(days: 365));

    // For end date selection, make sure we can't pick a date before the start date
    final DateTime firstAllowedDate = isStartDate ? oneYearAgo : _startDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: firstAllowedDate, // Set minimum date based on context
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before new start date, update end date to match start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Toggle frequency selection (morning, afternoon, evening)
  void _toggleFrequency(String time) {
    setState(() {
      switch (time) {
        case 'Morning':
          _morning = !_morning;
          break;
        case 'Afternoon':
          _afternoon = !_afternoon;
          break;
        case 'Evening':
          _evening = !_evening;
          break;
      }
    });
  }

  // Toggle food timing (before or after meals) - mutually exclusive
  void _toggleFoodTiming(String timing) {
    setState(() {
      switch (timing) {
        case 'Before Meals':
          _beforeMeals = true;
          _afterMeals = false;
          break;
        case 'After Meals':
          _beforeMeals = false;
          _afterMeals = true;
          break;
      }
    });
  }

  // Build frequency selection button
  Widget _buildFrequencyButton(String title, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleFrequency(title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primaryGreen
              : AppColor.secondaryBackgroundWhite,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          title,
          style: FontStyles.bodyBase.copyWith(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // Build food timing selection button
  Widget _buildFoodTimingButton(String title, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleFoodTiming(title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primaryGreen
              : AppColor.secondaryBackgroundWhite,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          title,
          style: FontStyles.bodyBase.copyWith(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // Add the medicine
  void _addMedicine() {
    // Validate input
    if (_medicineNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medicine name')),
      );
      return;
    }

    if (!_morning && !_afternoon && !_evening) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one time of day')),
      );
      return;
    }

    // Create medicine object
    final medicine = Medicine(
      id: '', // Will be set by the service
      name: _medicineNameController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      morning: _morning,
      afternoon: _afternoon,
      evening: _evening,
      beforeMeals: _beforeMeals,
      afterMeals: _afterMeals,
      notify: _notify,
    );

    // Add the medicine
    widget.onAddMedicine(medicine);

    // Reset form
    _medicineNameController.clear();
    setState(() {
      _morning = false;
      _afternoon = false;
      _evening = false;
      _beforeMeals = false;
      _afterMeals = true; // Reset to default "After Meals"
      _startDate = DateTime.now();
      _endDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine Name
              Text(
                'Medicine Name',
                style: FontStyles.bodyBase.copyWith(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColor.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _medicineNameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter medicine name',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Frequency
              Text(
                'Frequency',
                style: FontStyles.bodyBase.copyWith(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFrequencyButton('Morning', _morning),
                    const SizedBox(width: 8),
                    _buildFrequencyButton('Afternoon', _afternoon),
                    const SizedBox(width: 8),
                    _buildFrequencyButton('Evening', _evening),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Take Before or After Food - NEW SECTION
              Text(
                'Take Before or After Food',
                style: FontStyles.bodyBase.copyWith(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFoodTimingButton('Before Meals', _beforeMeals),
                    const SizedBox(width: 8),
                    _buildFoodTimingButton('After Meals', _afterMeals),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Course Start Date
              Text(
                'Course Start Date',
                style: FontStyles.bodyBase.copyWith(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColor.backgroundGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_formatDate(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: const Icon(
                        Icons.edit_calendar,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Course End Date
              Text(
                'Course End Date',
                style: FontStyles.bodyBase.copyWith(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColor.backgroundGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_formatDate(_endDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: const Icon(
                        Icons.edit_calendar,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notify Me Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _notify,
                    onChanged: (value) {
                      setState(() {
                        _notify = value ?? true;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text('Notify Me'),
                ],
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addMedicine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
