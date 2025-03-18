import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddMedicalRecordPopup extends StatefulWidget {
  final Function(String, String, DateTime) onAdd;

  const AddMedicalRecordPopup({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddMedicalRecordPopup> createState() => _AddMedicalRecordPopupState();
}

class _AddMedicalRecordPopupState extends State<AddMedicalRecordPopup> {
  final TextEditingController _headingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _headingController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Save the new medical record
  void _saveRecord() {
    // Validate inputs
    if (_headingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    // Set saving state
    setState(() {
      _isSaving = true;
    });

    // Call the onAdd callback
    widget.onAdd(
      _headingController.text.trim(),
      _descriptionController.text.trim(),
      _selectedDate,
    );

    // Close the popup
    Navigator.of(context).pop();
  }

  // Select a date
  Future<void> _selectDate() async {
    // Hide keyboard first
    FocusScope.of(context).unfocus();

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
  }

  @override
  Widget build(BuildContext context) {
    // Get available screen height
    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      backgroundColor: Colors.grey[200],
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: keyboardHeight > 0 ? 10.0 : 24.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight:
              screenHeight - (keyboardHeight > 0 ? keyboardHeight + 80 : 100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),

            // Form fields - Wrapped in Expanded and SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Title',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _headingController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          border: InputBorder.none,
                          hintText: 'BP Result',
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${DateFormat('dd').format(_selectedDate)}-${DateFormat('MMMM').format(_selectedDate)}-${DateFormat('yyyy').format(_selectedDate)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today_outlined,
                                  size: 24),
                              onPressed: _isSaving ? null : _selectDate,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: BoxConstraints(
                        minHeight: 150,
                        maxHeight: 200,
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                          hintText:
                              'Blood Pressure: 120/80 mmHG -(normal not need to worry)\nPulse Rate: 72 bpm\nStatus: Normal',
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),

                    // Add bottom padding to ensure content is scrollable
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Save button - Always at the bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF76C5DE), // Blue color
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
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
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
