import 'package:flutter/material.dart';

class AddPrescriptionMedicine extends StatelessWidget {
  const AddPrescriptionMedicine({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implement your Add Manually Medicine screen here
    return Scaffold(
      appBar: AppBar(title: const Text('Add By Prescription')),
      body: const Center(child: Text('Add Prescription Medicine Screen')),
    );
  }
}