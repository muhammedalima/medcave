import 'package:flutter/material.dart';
import 'package:medcave/common/geminifunction/alternate_medicine_finder.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/config/fonts/font.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicineResultScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final AlternateMedicineFinder medicineFinder;
  final String? medicineName; // For text-based search
  final String? imagePath; // For image-based search

  const MedicineResultScreen({
    Key? key,
    required this.initialData,
    required this.medicineFinder,
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
        result = await widget.medicineFinder
            .findAlternativesByName(widget.medicineName!);
      } else if (widget.imagePath != null) {
        try {
          result = await widget.medicineFinder
              .findAlternativesByImage(widget.imagePath!);
        } catch (e) {
          // Fallback if the image method fails
          print('Error with image search: $e');
          result = {
            'originalMedicine': 'Analysis Failed',
            'genericName': 'Unknown',
            'description':
                'We could not analyze the medicine image. Please try using text search instead.',
            'alternatives': [],
          };
        }
      } else {
        result = {
          'originalMedicine': 'Error',
          'genericName': 'Unknown',
          'description': 'Invalid search parameters',
          'alternatives': [],
        };
      }

      if (mounted) {
        setState(() {
          _medicineData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
        // Don't update _medicineData here to keep the initial placeholder data
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Alternatives'),
        backgroundColor: AppColor.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 20,
                height: 20,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _retrySearch,
            tooltip: 'Retry search',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message (if any)
              if (_errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Error loading data',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _retrySearch,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Original medicine card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medication,
                            color: AppColor.primaryBlue,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _medicineData['originalMedicine'] ??
                                  'Unknown Medicine',
                              style: FontStyles.heading.copyWith(fontSize: 20),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          if (_isLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generic Name: ${_medicineData['genericName'] ?? 'Unknown'}',
                        style: FontStyles.bodyStrong,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _medicineData['description'] ??
                            'No description available',
                        style: FontStyles.bodyBase,
                      ),
                    ],
                  ),
                ),
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
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColor.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Searching',
                            style: TextStyle(
                                fontSize: 12, color: AppColor.primaryBlue),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Get alternatives from _medicineData
              Expanded(
                child: _buildAlternativesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativesList() {
    final alternatives = _medicineData['alternatives'] as List<dynamic>? ?? [];

    if (_isLoading && alternatives.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Searching for alternatives...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (alternatives.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No alternatives found for this medicine.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (!_isLoading && _errorMessage.isEmpty)
              ElevatedButton.icon(
                onPressed: _retrySearch,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: alternatives.length,
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
    );
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
}

// Card for displaying alternative medicines
class AlternativeMedicineCard extends StatelessWidget {
  final String name;
  final String linkToBuy;
  final VoidCallback onTapLink;

  const AlternativeMedicineCard({
    Key? key,
    required this.name,
    required this.linkToBuy,
    required this.onTapLink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: linkToBuy.isNotEmpty ? onTapLink : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: FontStyles.bodyStrong.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    if (linkToBuy.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap to buy online',
                        style: TextStyle(
                          color: AppColor.primaryGreen,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (linkToBuy.isNotEmpty)
                Icon(
                  Icons.shopping_cart,
                  color: AppColor.primaryGreen,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
