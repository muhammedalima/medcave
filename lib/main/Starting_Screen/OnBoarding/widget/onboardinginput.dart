import 'package:flutter/material.dart';
import 'package:medcave/config/colors/appcolor.dart';

class InputFieldContainer extends StatelessWidget {
  final Widget child;

  const InputFieldContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: child,
    );
  }
}
