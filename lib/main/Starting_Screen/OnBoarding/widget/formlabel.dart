
// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

class FormLabelText extends StatelessWidget {
  final String text;

  const FormLabelText({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}