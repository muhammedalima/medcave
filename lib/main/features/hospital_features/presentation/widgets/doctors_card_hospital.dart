import 'package:flutter/material.dart';
import 'package:medcave/main/features/hospital_features/presentation/pages/doctors_screen.dart';

class DoctorCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String specialization;
  final bool isAvailableToday;
  final List<String> availableSlots;
  final String lastUpdated;
  final String qualification;
  final int yearsOfExperience;

  const DoctorCard({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.specialization,
    required this.isAvailableToday,
    required this.availableSlots,
    required this.lastUpdated,
    required this.qualification,
    required this.yearsOfExperience,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToDoctorDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Doctor details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialization,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Availability indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailableToday
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isAvailableToday ? 'Available today' : 'Not available',
                  style: TextStyle(
                    fontSize: 12,
                    color: isAvailableToday
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDoctorDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorDetailsScreen(
          firstName: firstName,
          lastName: lastName,
          specialization: specialization,
          availableSlots: availableSlots,
          lastUpdated: lastUpdated,
          qualification: qualification,
          yearsOfExperience: yearsOfExperience,
        ),
      ),
    );
  }
}
