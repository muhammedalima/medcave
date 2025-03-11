import 'package:flutter/material.dart';

class Buttonarrrowicon extends StatelessWidget {
  final double rotateAngle;
  final Widget? destination;
  final bool replaceRoute;

  const Buttonarrrowicon({
    super.key,
    this.rotateAngle = 0.0,
    this.destination,
    this.replaceRoute = false,
  });

  void _handleNavigation(BuildContext context) {
    if (destination == null) return;
    
    if (replaceRoute) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination!),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: destination != null ? () => _handleNavigation(context) : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Transform.rotate(
          angle: rotateAngle,
          child: const Icon(
            Icons.arrow_outward,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}