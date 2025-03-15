// Custom tab bar that doesn't use the built-in TabBar widget
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontSize: 22,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                ),
              ),
            ),
            // Custom indicator
            Container(
              height: 2,
              width:
                  title.length * 11.0, // Approximate width based on text length
              color: isSelected ? Colors.black : Colors.transparent,
            ),
            const SizedBox(
                height: 2), // Small gap between indicator and content
          ],
        ),
      ),
    );
  }
}
