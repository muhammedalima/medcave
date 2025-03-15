// lib/Users/Mobilescreens/features/personal_profile/widget/past_medicines_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medcave/common/database/User/medicine/user_medicine.dart';
import 'package:medcave/config/fonts/font.dart';

class PastMedicinesSection extends StatelessWidget {
  final List<Medicine> medicines;
  final VoidCallback onViewAllPressed;
  
  const PastMedicinesSection({
    Key? key,
    required this.medicines,
    required this.onViewAllPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Past Medicines Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Past Medicines',
              style: FontStyles.heading,
            ),
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: onViewAllPressed,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text(
                  'view all',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Past Medicines List
        medicines.isEmpty 
            ? const Text('No past medicines')
            : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: medicines.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return _buildPastMedicineItem(medicines[index]);
                },
              ),
      ],
    );
  }

  Widget _buildPastMedicineItem(Medicine medicine) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String dateRange = "${formatter.format(medicine.startDate)}-${formatter.format(medicine.endDate ?? medicine.startDate)}";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medicine.name,
          style: FontStyles.bodyStrong,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...medicine.schedule.asMap().entries.map((entry) {
                    final isLast = entry.key == medicine.schedule.length - 1;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        if (!isLast) 
                          const Text(" / ", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    );
                  }).toList(),
                  const Text(" - ", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  Text(
                    dateRange,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}