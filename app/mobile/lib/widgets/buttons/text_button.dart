import 'package:flutter/material.dart';
import '../../styles/colors.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  final Color? backgroundColor;

  final Color? foregroundColor;

  final double borderRadius;

  final EdgeInsetsGeometry padding;

  final double elevation;

  const CustomTextButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primaryColor;
    final fg = foregroundColor ?? (ThemeData.estimateBrightnessForColor(bg) == Brightness.dark ? Colors.white : Colors.black);

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: fg),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: elevation,
        padding: padding,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      ),
    );
  }
}
