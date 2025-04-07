import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medcave/main/commonWidget/customnavbar.dart';
import 'package:medcave/main/features/alternate_medicine_finder/presentation/pages/alternate_medicine_page.dart';
import 'package:medcave/main/features/home_screen/widget/camera_widget.dart';
import 'package:medcave/common/alternatemedicinefinerfunctions/alternate_medicine_finder.dart';
import 'package:medcave/common/alternatemedicinefinerfunctions/text_extractor.dart';

class ScanAlternateMedicine extends StatefulWidget {
  const ScanAlternateMedicine({Key? key}) : super(key: key);

  @override
  State<ScanAlternateMedicine> createState() => _ScanAlternateMedicineState();
}

class _ScanAlternateMedicineState extends State<ScanAlternateMedicine> {
  final AlternateMedicineFinder _medicineFinder = AlternateMedicineFinder();
  final MedicineTextExtractor _textExtractor = MedicineTextExtractor();
  final bool _isLoading = false;

  void _processImage(File imageFile) {
    // Navigate to results page with placeholder data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineResultScreen(
          initialData: const {
            'originalMedicine': 'Analyzing...',
            'genericName': 'Please wait',
            'description':
                'We are analyzing your medicine image. This may take a moment.',
            'alternatives': [],
          },
          imagePath: imageFile.path,
          medicineFinder: _medicineFinder,
          textExtractor: _textExtractor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        onPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Take a photo of your prescription',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: MedicineImageCapture(
                  isLoading: _isLoading,
                  onImageSelected: _processImage,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}