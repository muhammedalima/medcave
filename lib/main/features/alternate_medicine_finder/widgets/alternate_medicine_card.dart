import 'package:flutter/material.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Medicine info (left side)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine name
                Text(
                  name,
                  style: FontStyles.bodyStrong.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // "Tap to buy online" text
                if (linkToBuy.isNotEmpty)
                  Text(
                    'Tap to buy online',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),

          // Shopping cart icon (right side)
          GestureDetector(
            onTap: linkToBuy.isNotEmpty ? onTapLink : null,
            child: Container(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.shopping_cart,
                color: linkToBuy.isNotEmpty
                    ? Colors.grey
                    : Colors.grey.withOpacity(0.5),
                size: 32,
              ),
            ),
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
    );
  }
}
