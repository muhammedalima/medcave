import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medcave/common/database/model/User/medicine/user_medicine_db.dart';
import 'package:medcave/config/fonts/font.dart';

class PastMedicinesSection extends StatefulWidget {
  final List<Medicine> medicines;
  final VoidCallback onViewAllPressed;
  final Function(String)? onMedicineDeleted; // Callback for medicine deletion

  const PastMedicinesSection({
    Key? key,
    required this.medicines,
    required this.onViewAllPressed,
    this.onMedicineDeleted,
  }) : super(key: key);

  @override
  State<PastMedicinesSection> createState() => _PastMedicinesSectionState();
}

class _PastMedicinesSectionState extends State<PastMedicinesSection> {
  bool _viewingAll = false;
  static const int _initialDisplayCount = 3; // Show 3 items initially

  @override
  Widget build(BuildContext context) {
    // Hide the entire section if there are no medicines
    if (widget.medicines.isEmpty) {
      return const SizedBox.shrink(); // Return an empty widget
    }

    // Determine whether to show the "View All" button
    final bool shouldShowViewAll =
        widget.medicines.length > _initialDisplayCount;

    // Determine how many items to display
    final int displayCount = _viewingAll
        ? widget.medicines.length
        : widget.medicines.length.clamp(0, _initialDisplayCount);

    // Get the medicines to display
    final displayedMedicines = widget.medicines.take(displayCount).toList();

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
            // Only show "View All" button if needed
            if (shouldShowViewAll)
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _viewingAll = !_viewingAll;
                    });

                    // Only call the external callback when showing all
                    if (!_viewingAll) {
                      widget.onViewAllPressed();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: Text(
                    _viewingAll ? 'show less' : 'view all',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Past Medicines List
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: displayedMedicines.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            return _buildDismissibleMedicineItem(
                context, displayedMedicines[index]);
          },
        ),
      ],
    );
  }

  // Build a dismissible medicine item (swipe to delete)
  Widget _buildDismissibleMedicineItem(
      BuildContext context, Medicine medicine) {
    return Dismissible(
      key: Key(medicine.id),
      direction: DismissDirection.endToStart, // Only allow right to left swipe
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        bool? result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Medicine'),
            content: Text(
                'Are you sure you want to delete ${medicine.name} from your past medicines?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      onDismissed: (direction) {
        if (widget.onMedicineDeleted != null) {
          widget.onMedicineDeleted!(medicine.id);
        }
      },
      child: _buildPastMedicineItem(medicine),
    );
  }

  Widget _buildPastMedicineItem(Medicine medicine) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String dateRange =
        "${formatter.format(medicine.startDate)}-${formatter.format(medicine.endDate)}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medicine.name,
            style: FontStyles.bodyStrong.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                            entry.value.toLowerCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          if (!isLast)
                            const Text(" / ",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16)),
                        ],
                      );
                    }).toList(),
                    const Text(" - ",
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
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
      ),
    );
  }
}
