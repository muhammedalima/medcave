import 'package:flutter/material.dart';

class OnboardingArrowIcon extends StatelessWidget {
  final double rotateAngle;
  final VoidCallback onclick;

  const OnboardingArrowIcon({
    super.key,
    required this.rotateAngle,
    required this.onclick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onclick,
      child: Transform.rotate(
        angle: rotateAngle,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            
            Icons.arrow_forward,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}


