import 'package:flutter/material.dart';
import 'package:medcave/config/fonts/font.dart';
import 'package:medcave/main/features/hospital_features/model/hospitaldata.dart';
import 'package:url_launcher/url_launcher.dart';

class PalliativeCareIndicator extends StatelessWidget {
  final String hospitalId; // Add hospitalId to fetch specific hospital data

  const PalliativeCareIndicator({
    Key? key,
    required this.hospitalId, required bool isAvailable, required String description, required String contactNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: HospitalData.getHospitalById(hospitalId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Show nothing while loading
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink(); // Show nothing on error
        }

        final hospitalData = snapshot.data!;
        final palliativeCare = hospitalData['palliativeCare'] as Map<String, dynamic>;
        final bool isAvailable = palliativeCare['available'] ?? false;
        final String description = palliativeCare['description'] ?? '';
        final String contactNumber = palliativeCare['contactNumber'] ?? '';

        // Only show indicator if palliative care is available
        if (!isAvailable) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => _showPalliativeCareInfo(context, description, contactNumber),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 4),
                Text(
                  'Palliative care unit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPalliativeCareInfo(
      BuildContext context, String description, String contactNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFECD775), // Gold/yellow background
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Palliative Care Available',
                      style: FontStyles.heading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: FontStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF69B5D6), // Blue background for contact
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Contact - $contactNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // Close the dialog
                            Navigator.pop(context);
                            // Launch phone dialer
                            final Uri phoneUri = Uri(
                              scheme: 'tel',
                              path: contactNumber.replaceAll(' ', ''),
                            );
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            }
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}