import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/features/home_screen/presentation/pages/alternate_medicine_view.dart';
import 'package:medcave/common/geminifunction/alternate_medicine_finder.dart';
import 'package:medcave/config/colors/appcolor.dart';

class TypeAlternateMedicine extends StatefulWidget {
  const TypeAlternateMedicine({Key? key}) : super(key: key);

  @override
  State<TypeAlternateMedicine> createState() => _TypeAlternateMedicineState();
}

class _TypeAlternateMedicineState extends State<TypeAlternateMedicine> {
  final TextEditingController _medicineController = TextEditingController();
  final AlternateMedicineFinder _medicineFinder = AlternateMedicineFinder();
  String _errorMessage = '';

  @override
  void dispose() {
    _medicineController.dispose();
    super.dispose();
  }

  void _findAlternatives() {
    final medicineName = _medicineController.text.trim();
    if (medicineName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a medicine name';
      });
      return;
    }

    // Navigate immediately to results page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineResultScreen(
          initialData: {
            'originalMedicine': medicineName,
            'genericName': 'Searching...',
            'description': 'We are finding alternative medicines for $medicineName. Please wait a moment.',
            'alternatives': [],
          },
          medicineName: medicineName,
          medicineFinder: _medicineFinder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Alternative Medicines'),
        backgroundColor: AppColor.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type your medicine name',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the brand name or generic name of the medicine you want alternatives for',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _medicineController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Paracetamol, Lipitor, Metformin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.medication),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: (_) => _findAlternatives(),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _findAlternatives,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Search For Alternatives',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}