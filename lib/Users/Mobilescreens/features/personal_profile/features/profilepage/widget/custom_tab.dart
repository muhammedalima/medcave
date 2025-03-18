import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const CustomTabBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16),
      // Add height constraint to prevent overflow
      height: 65, // Increased height to accommodate text and indicator
      child: Row(
        children: [
          _buildTab(0, 'Medications'),
          _buildTab(1, 'Medical-History'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 8), // Reduced vertical padding
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Custom indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2,
              width:
                  title.length * 11.0, // Approximate width based on text length
              color: isSelected ? Colors.black : Colors.transparent,
            ),
            // No additional SizedBox needed here
          ],
        ),
      ),
    );
  }
}
