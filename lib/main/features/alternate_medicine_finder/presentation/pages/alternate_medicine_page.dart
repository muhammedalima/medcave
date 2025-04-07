import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:medcave/main/commonWidget/customnavbar.dart';
import 'package:medcave/main/features/alternate_medicine_finder/widgets/alternate_medicine_card.dart';
import 'package:medcave/main/features/alternate_medicine_finder/widgets/alternate_widgets.dart';
import 'package:medcave/main/features/alternate_medicine_finder/widgets/orginal_medicine.dart';
import 'package:medcave/common/alternatemedicinefinerfunctions/alternate_medicine_finder.dart';
import 'package:medcave/common/alternatemedicinefinerfunctions/text_extractor.dart';
import 'package:medcave/config/fonts/font.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicineResultScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final AlternateMedicineFinder medicineFinder;
  final MedicineTextExtractor? textExtractor;
  final String? medicineName; // For text-based search
  final String? imagePath; // For image-based search

  const MedicineResultScreen({
    Key? key,
    required this.initialData,
    required this.medicineFinder,
    this.textExtractor,
    this.medicineName,
    this.imagePath,
  }) : super(key: key);

  @override
  State<MedicineResultScreen> createState() => _MedicineResultScreenState();
}

class _MedicineResultScreenState extends State<MedicineResultScreen> {
  late Map<String, dynamic> _medicineData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _medicineData = widget.initialData;
    _fetchMedicineData();
  }

  Future<void> _fetchMedicineData() async {
    try {
      Map<String, dynamic> result;

      // Determine which API method to call
      if (widget.medicineName != null) {
        // Text-based search - direct lookup
        result = await widget.medicineFinder
            .findAlternativesByName(widget.medicineName!);

        // Check if medicine not found
        if (result['alternatives'] == null ||
            (result['alternatives'] is List &&
                result['alternatives'].isEmpty)) {
          // Pop back with error message
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Unable to process your request. Please check the spelling of the medicine.'),
                duration: Duration(seconds: 4),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else if (widget.imagePath != null && widget.textExtractor != null) {
        try {
          // Image-based search - first extract name, then find alternatives
          final extractedName = await widget.textExtractor!
              .extractMedicineNameFromImage(widget.imagePath!);

          if (extractedName == null) {
            // Pop back with error for image text extraction failure
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Unable to process your request. Please take a clearer image of the medicine.'),
                  duration: Duration(seconds: 4),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          } else {
            result = await widget.medicineFinder
                .findAlternativesByName(extractedName);

            // Check if no results were found for the extracted name
            if (result['alternatives'] == null ||
                (result['alternatives'] is List &&
                    result['alternatives'].isEmpty)) {
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'No alternatives found for "$extractedName". Please try a different medicine.'),
                    duration: const Duration(seconds: 4),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }
        } catch (e) {
          // Pop back with error for image processing failure
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Unable to process your request. Please take a clearer image of the medicine.'),
                duration: Duration(seconds: 4),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        // Invalid parameters - show error and pop back
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid search parameters. Please try again.'),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _medicineData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Log the error in debug mode
        if (kDebugMode) {
          print('Error in medicine search: $e');
        }

        // Pop back with generic error
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retrySearch() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    _fetchMedicineData();
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        customTitle: 'Alternate Medicines',
        rightIcon: _isLoading ? null : Icons.refresh,
        onRightPressed: _isLoading ? null : _retrySearch,
        onPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        // Make everything scrollable by wrapping with SingleChildScrollView
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original medicine card - passing originalMedicine
                OriginalMedicineCard(
                  medicineData: _medicineData,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // Alternatives section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Alternative Medicines',
                      style: FontStyles.heading.copyWith(fontSize: 18),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Alternatives list with fixed height instead of Expanded
                _buildAlternativesList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativesList() {
    final alternatives = _medicineData['alternatives'] as List<dynamic>? ?? [];

    if (_isLoading && alternatives.isEmpty) {
      return const AlternativesLoadingWidget();
    }

    if (alternatives.isEmpty) {
      return NoAlternativesFoundWidget(
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onRetry: _retrySearch,
      );
    }

    // Use a non-scrollable list with a fixed height
    // or all items if there are fewer than a threshold
    final int itemCount = alternatives.length;
    final double itemHeight = 100.0; // Approximate height per item
    final double maxHeight =
        MediaQuery.of(context).size.height * 0.5; // 50% of screen height
    final double calculatedHeight = itemCount * itemHeight;
    final double listHeight =
        calculatedHeight < maxHeight ? calculatedHeight : maxHeight;

    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        // Disable scrolling physics on this ListView since parent ScrollView handles scrolling
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: alternatives.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final alternative = alternatives[index];

          // Handle both Map and String alternatives
          String name;
          String linkToBuy = '';

          if (alternative is Map) {
            name = alternative['name'] ?? 'Unknown';
            linkToBuy = alternative['linktobuy'] ?? '';
          } else {
            name = alternative.toString();
          }

          return AlternativeMedicineCard(
            name: name,
            linkToBuy: linkToBuy,
            onTapLink: () => _launchUrl(linkToBuy),
          );
        },
      ),
    );
  }
}
