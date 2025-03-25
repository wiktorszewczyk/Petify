import 'package:flutter/material.dart';
import '../../styles/colors.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final bool obscureText;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: AppColors.primaryColor),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
        ),
    );
  }
}

