import 'package:flutter/material.dart';
import 'package:medcave/config/fonts/font.dart';

class HospitalTabBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final Function(String) onSearch;

  const HospitalTabBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<HospitalTabBar> createState() => _HospitalTabBarState();
}

class _HospitalTabBarState extends State<HospitalTabBar> {
  final TextEditingController _searchController = TextEditingController();

  // List of placeholder texts for each tab
  final List<String> _searchHints = [
    'Search by doctor name or specialization',
    'Search for lab tests',
    'Search for medicines',
    'Search for vaccines'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HospitalTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear search when tab changes
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _searchController.clear();
    }
  }

  void _onSearchChanged() {
    widget.onSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 16),
          height: 48,
          // Wrap the Row with SingleChildScrollView to make it horizontally scrollable
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTab(0, 'Doctors'),
                _buildTab(1, 'Lab Test'),
                _buildTab(2, 'Medicines'),
                _buildTab(3, 'Vaccines'),
              ],
            ),
          ),
        ),

        // Search bar that changes based on selected tab
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _searchHints[widget.selectedIndex],
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String title) {
    final bool isSelected = index == widget.selectedIndex;
    return GestureDetector(
      onTap: () => widget.onTabSelected(index),
      child: Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                title,
                style: FontStyles.heading.copyWith(
                  color: isSelected ? Colors.black : Colors.grey,
                ),
              ),
            ),
            // Custom indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2,
              width: title.length * 11.0,
              color: isSelected ? Colors.black : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
