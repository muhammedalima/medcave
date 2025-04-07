import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/main/features/hospital_features/model/hospitaldata.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/medicine_card_hospital.dart';

class MedicineList extends StatefulWidget {
  final String hospitalId;
  final String searchQuery;

  const MedicineList({
    Key? key,
    required this.hospitalId,
    required this.searchQuery,
  }) : super(key: key);

  @override
  State<MedicineList> createState() => _MedicineListState();
}

class _MedicineListState extends State<MedicineList> {
  late Future<String> _hospitalIdFuture;

  @override
  void initState() {
    super.initState();
    _hospitalIdFuture = HospitalData.getSelectedHospitalId();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _hospitalIdFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final hospitalId = snapshot.data!;
        final medicineStream = FirebaseFirestore.instance
            .collection('HospitalData')
            .doc(hospitalId)
            .collection('medicinedetails')
            .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: medicineStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No medicines found.'));
            }

            final allMedicines = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Add ID if needed for update/delete
              return data;
            }).toList();

            // Filter by searchQuery
            final filteredMedicines = widget.searchQuery.isEmpty
                ? allMedicines
                : allMedicines.where((medicine) {
                    final name =
                        (medicine['name'] ?? '').toString().toLowerCase();
                    final description = (medicine['description'] ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(widget.searchQuery.toLowerCase()) ||
                        description.contains(widget.searchQuery.toLowerCase());
                  }).toList();

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredMedicines.length,
              itemBuilder: (context, index) {
                final medicine = filteredMedicines[index];
                return HospitalMedicineCard(
                  medicineName: medicine['name'] ?? '',
                  isAvailable: medicine['available'] ?? false,
                  medicineDetails: medicine,
                );
              },
            );
          },
        );
      },
    );
  }
}
