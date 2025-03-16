import 'package:flutter/material.dart';

class AddManuallyMedicine extends StatelessWidget {
  const AddManuallyMedicine({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implement your Add Manually Medicine screen here
    return Scaffold(
      appBar: AppBar(title: const Text('Add Manually')),
      body: const Center(child: Text('Add Manually Medicine Screen')),
    );
  }
}