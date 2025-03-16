import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/features/personal_profile/presentation/pages/add_manually_medcine.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/config/fonts/font.dart';

// File: add_medication_popup.dart

class AddMedicationPopup extends StatelessWidget {
  const AddMedicationPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scan Prescription button (blue)
          _buildOptionButton(
            context: context,
            title: 'Scan\nPrescription',
            color: AppColor.primaryBlue, // Light blue color
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddPrescriptionMedicine(),
                ),
              );
            },
          ),

          // OR divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Divider(
                    color: AppColor.darkBlack,
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR',
                      style: FontStyles.bodyBase
                          .copyWith(color: AppColor.darkBlack)),
                ),
                const Expanded(
                  child: Divider(
                    color: AppColor.darkBlack,
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ),

          // Add Manually button (yellow)
          _buildOptionButton(
            context: context,
            title: 'Add\nManually',
            color: AppColor.primaryGreen, // Yellow color
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddManuallyMedicine(),
                ),
              );
            },
          ),

          // Add padding at the bottom for SafeArea
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: FontStyles.heading.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
        ),
      ),
    );
  }
}

// Helper method to show the popup as a bottom sheet
void showAddMedicationPopup(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const SafeArea(
      child: AddMedicationPopup(),
    ),
  );
}

// These are placeholder classes that you'll need to implement or import


class AddPrescriptionMedicine extends StatelessWidget {
  const AddPrescriptionMedicine({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implement your Add Prescription Medicine screen here
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Prescription')),
      body: const Center(child: Text('Add Prescription Medicine Screen')),
    );
  }
}