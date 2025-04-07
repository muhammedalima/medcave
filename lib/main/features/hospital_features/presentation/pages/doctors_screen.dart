import 'package:flutter/material.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String specialization;
  final List<String> availableSlots;
  final String lastUpdated;
  final String qualification;
  final int yearsOfExperience;

  const DoctorDetailsScreen({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.specialization,
    required this.availableSlots,
    required this.lastUpdated,
    required this.qualification,
    required this.yearsOfExperience,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Name
            Text(
              '$firstName $lastName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Specialization
            Text(
              specialization,
              style: TextStyle(
                fontSize: 18,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            // Qualification
            _buildInfoSection(
              title: 'Qualification',
              content: qualification,
            ),
            
            // Experience
            _buildInfoSection(
              title: 'Years of Experience',
              content: '$yearsOfExperience years',
            ),
            
            // Last Updated
            _buildInfoSection(
              title: 'Last Updated',
              content: lastUpdated,
            ),
            
            // Available Slots
            const SizedBox(height: 8),
            const Text(
              'Available Slots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...availableSlots.map((slot) => _buildSlotItem(slot)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotItem(String slot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 20, color: Colors.blue),
            const SizedBox(width: 12),
            Text(
              slot,
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
}