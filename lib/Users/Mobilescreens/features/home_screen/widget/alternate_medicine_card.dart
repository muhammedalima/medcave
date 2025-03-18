import 'package:flutter/material.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/config/fonts/font.dart';

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