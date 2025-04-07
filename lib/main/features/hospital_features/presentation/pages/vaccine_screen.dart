import 'package:flutter/material.dart';

class VaccineDetailScreen extends StatelessWidget {
  final Map<String, dynamic> vaccine;

  const VaccineDetailScreen({
    Key? key,
    required this.vaccine,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vaccine Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vaccine icon/image banner
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.green.shade50,
              child: Center(
                child: Icon(
                  Icons.health_and_safety,
                  size: 100,
                  color: Colors.green.shade400,
                ),
              ),
            ),

            // Vaccine details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    vaccine['vaccineName'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Age group
                  _buildDetailRow(
                    title: 'Age Group',
                    value: vaccine['ageGroup'],
                    icon: Icons.people,
                  ),
                  const SizedBox(height: 12),

                  // Availability
                  _buildDetailRow(
                    title: 'Status',
                    value: vaccine['available'] ? 'Available' : 'Not Available',
                    valueColor: vaccine['available']
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    icon: Icons.check_circle,
                    iconColor: vaccine['available'] ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 24),

                  // Description header
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description content
                  Text(
                    vaccine['description'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Book appointment button
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 50,
                  //   child: ElevatedButton(
                  //     onPressed: vaccine['available']
                  //         ? () {
                  //             // Handle booking functionality
                  //             ScaffoldMessenger.of(context).showSnackBar(
                  //                 SnackBar(
                  //                     content: Text(
                  //                         'Booking vaccine appointment...')));
                  //           }
                  //         : null,
                  //     style: ElevatedButton.styleFrom(
                  //       foregroundColor: Colors.white,
                  //       backgroundColor: Colors.green,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //       disabledBackgroundColor: Colors.grey.shade300,
                  //     ),
                  //     child: const Text(
                  //       'Book Appointment',
                  //       style: TextStyle(
                  //         fontSize: 16,
                  //         fontWeight: FontWeight.bold,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor ?? Colors.blue,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          '$title:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
