import 'package:flutter/material.dart';

class MedicineDetailScreen extends StatelessWidget {
  final Map<String, dynamic> medicine;

  const MedicineDetailScreen({
    Key? key,
    required this.medicine,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicine['medicineName'] ?? 'Medicine Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine image header
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                image: medicine['imageUrl']?.isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(medicine['imageUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: medicine['imageUrl']?.isEmpty != false
                  ? Center(
                      child: Icon(
                        Icons.medication,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                    )
                  : null,
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine name and availability badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          medicine['medicineName'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (medicine['isAvailable'] ?? false) 
                              ? Colors.green.shade100 
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (medicine['isAvailable'] ?? false) 
                              ? 'Available' 
                              : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: (medicine['isAvailable'] ?? false) 
                                ? Colors.green.shade800 
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Price information
                  Row(
                    children: [
                      Text(
                        medicine['price'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '₹${(int.parse((medicine['price'] ?? '₹0').replaceAll('₹', '')) * 1.15).toInt()}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '15% off',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Information sections
                  _buildInfoSection(
                    'Description',
                    medicine['description'] ?? 'No description available.',
                  ),
                  
                  _buildInfoSection(
                    'Manufacturer',
                    medicine['manufacturer'] ?? 'Information not available',
                  ),
                  
                  _buildInfoSection(
                    'Dosage',
                    medicine['dosage'] ?? 'Information not available',
                  ),
                  
                  _buildInfoSection(
                    'Side Effects',
                    medicine['sideEffects'] ?? 'Information not available',
                  ),
                  
                  // Last updated
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'Last Updated: ${medicine['lastUpdated'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Add to cart button - only if available
                  if (medicine['isAvailable'] ?? false)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${medicine['medicineName']} added to cart'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300),
        ],
      ),
    );
  }
}