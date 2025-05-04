import 'package:flutter/material.dart';
import '../../styles/colors.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final double size;
  final Color? iconColor;
  final double? iconSize;

  const ActionButton({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    this.size = 60.0,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Center(
            child: Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: iconSize ?? size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}