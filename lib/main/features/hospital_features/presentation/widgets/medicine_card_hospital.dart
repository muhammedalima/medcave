import 'package:flutter/material.dart';
import 'package:medcave/main/features/hospital_features/presentation/pages/medicine_screen.dart';

class HospitalMedicineCard extends StatelessWidget {
  final String medicineName;
  final bool isAvailable;
  final Map<String, dynamic> medicineDetails;

  const HospitalMedicineCard({
    Key? key,
    required this.medicineName,
    required this.isAvailable,
    required this.medicineDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MedicineDetailScreen(medicine: medicineDetails),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: medicineDetails['imageUrl']?.isNotEmpty == true
                      ? DecorationImage(
                          image: NetworkImage(medicineDetails['imageUrl']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: medicineDetails['imageUrl']?.isEmpty != false
                    ? Center(
                        child: Icon(
                          Icons.medication,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : null,
              ),
            ),

            // Medicine details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Out of Stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAvailable
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
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
