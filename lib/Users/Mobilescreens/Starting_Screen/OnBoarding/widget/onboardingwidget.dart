import 'package:flutter/material.dart';

class Onboardingarrrowicon extends StatelessWidget {
  final double rotateAngle;
  final VoidCallback onclick;

  const Onboardingarrrowicon(
      {super.key, required this.onclick, this.rotateAngle = 0.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
          onTap: onclick,
          child: Transform.rotate(
            angle: rotateAngle,
            child: const Icon(
              Icons.arrow_outward,
              color: Colors.white,
              size: 28,
            ),
          )),
    );
  }
}