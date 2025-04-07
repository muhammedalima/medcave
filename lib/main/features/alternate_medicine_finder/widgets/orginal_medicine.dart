import 'package:flutter/material.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/config/fonts/font.dart';

class OriginalMedicineCard extends StatelessWidget {
  final Map<String, dynamic> medicineData;
  final bool isLoading;

  const OriginalMedicineCard({
    Key? key,
    required this.medicineData,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColor.backgroundWhite,
      elevation: .2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              medicineData['originalMedicine'] ?? 'Unknown Medicine',
              style: FontStyles.heading.copyWith(fontSize: 20),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              medicineData['genericName'] != null
                  ? '(Generic name is ${medicineData['genericName']})'
                  : '',
              style: FontStyles.bodyStrong,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Text(
              medicineData['description'] ?? 'No description available',
              style: FontStyles.bodyBase,
            ),
          ],
        ),
      ),
    );
  }
}
