import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medcave/main/commonWidget/customnavbar.dart';
import 'package:medcave/main/features/personal_profile/features/medication/widget/addnew_medcine_popup.dart';
import 'package:medcave/common/database/model/User/medicine/user_medicine_db.dart';
import 'package:medcave/common/database/service/medcine_services.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class AddPrescriptionMedicine extends StatefulWidget {
  const AddPrescriptionMedicine({Key? key}) : super(key: key);

  @override
  State<AddPrescriptionMedicine> createState() =>
      _AddPrescriptionMedicineState();
}

class _AddPrescriptionMedicineState extends State<AddPrescriptionMedicine> {
  final List<Medicine> _addedMedicines = [];
  final MedicineService _medicineService = MedicineService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Show prescription capture options when the screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPrescriptionOptions();
    });
  }

  // Show options to capture or select prescription
  void _showPrescriptionOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Prescription'),
        content: const Text('How would you like to add your prescription?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _captureImage(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _captureImage(ImageSource.gallery);
            },
            child: const Text('Choose from Gallery'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddMedicinePopup();
            },
            child: const Text('Add Manually'),
          ),
        ],
      ),
    );
  }

  // Capture or select an image
  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _isProcessing = true;
        });

        // Process the image to extract text
        await _processImage(File(image.path));

        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  // Process the image to extract medicine information
  Future<void> _processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      // Extract medicine information using simple pattern matching
      final extractedInfo = _extractMedicineInfo(recognizedText.text);

      // Show the popup with pre-filled data
      _showAddMedicinePopup(prefillName: extractedInfo['name']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
      // Show the add medicine popup without pre-filled data
      _showAddMedicinePopup();
    }
  }

  // Extract medicine name and frequency using basic pattern matching
  Map<String, String?> _extractMedicineInfo(String text) {
    String? medicineName;

    // Simple pattern matching to find medicine names (this is a basic implementation)
    // In a real app, this would be more sophisticated with ML models

    // Look for common medicine name patterns
    final nameRegex = RegExp(r'([A-Z][a-z]+\s\d+\s?mg)', multiLine: true);
    final nameMatches = nameRegex.allMatches(text);
    if (nameMatches.isNotEmpty) {
      medicineName = nameMatches.first.group(0);
    }

    return {
      'name': medicineName,
    };
  }

  // Show the add medicine popup
  void _showAddMedicinePopup({String? prefillName}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddNewMedicinePopup(
        onAddMedicine: (medicine) {
          setState(() {
            _addedMedicines.add(medicine);
          });
          Navigator.of(context).pop();
        },
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );

    // Pre-fill the medicine name if provided
    if (prefillName != null && prefillName.isNotEmpty) {
      // This must be handled in the AddNewMedicinePopup widget itself
      // as we cannot directly access the controller from here
    }
  }

  // Format the medicine schedule as string (e.g., "morning / noon / night")
  String _formatSchedule(Medicine medicine) {
    List<String> times = [];
    if (medicine.morning) times.add("morning");
    if (medicine.afternoon) times.add("noon");
    if (medicine.evening) times.add("night");
    return times.join(" / ");
  }

  // Format food timing as string
  String _formatFoodTiming(Medicine medicine) {
    if (medicine.beforeMeals) {
      return "before meals";
    } else if (medicine.afterMeals) {
      return "after meals";
    } else {
      return "";
    }
  }

  // Format complete medicine details as string
  String _formatMedicineDetails(Medicine medicine) {
    String schedule = _formatSchedule(medicine);
    String foodTiming = _formatFoodTiming(medicine);

    if (foodTiming.isNotEmpty) {
      return "$schedule - $foodTiming";
    }

    return schedule;
  }

  // Format date range as string
  String _formatDateRange(Medicine medicine) {
    final formatter = DateFormat('dd-MM-yyyy');
    return 'From ${formatter.format(medicine.startDate)} to ${formatter.format(medicine.endDate)}';
  }

  // Save all medicines to the database
  Future<void> _saveAllMedicines() async {
    if (_addedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medicines to add')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _medicineService.addMedicines(_addedMedicines);

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicines added successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add medicines: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Delete a medicine from the list
  void _deleteMedicine(int index) {
    setState(() {
      _addedMedicines.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        onPressed: () => Navigator.pop(context),
      ),
      body: _isLoading || _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_isProcessing
                      ? 'Processing prescription...'
                      : 'Saving medicines...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Medicine added',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List of added medicines
                  Expanded(
                    child: _addedMedicines.isEmpty
                        ? const Center(
                            child: Text('No medicines added yet'),
                          )
                        : ListView.separated(
                            itemCount: _addedMedicines.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final medicine = _addedMedicines[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  medicine.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatMedicineDetails(medicine),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _formatDateRange(medicine),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.grey),
                                  onPressed: () => _deleteMedicine(index),
                                ),
                              );
                            },
                          ),
                  ),

                  // Add More Medicine button
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Add More Medicine',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _showPrescriptionOptions,
                            icon: const Icon(
                              Icons.add,
                              color: AppColor.darkBlack,
                            ),
                            label: const Text(
                              'Add',
                              style: TextStyle(
                                color: AppColor.darkBlack,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Add all to meds button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAllMedicines,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add all to meds',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}