import 'package:flutter/material.dart';
import 'colors.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primaryColor,
  scaffoldBackgroundColor: AppColors.backgroundColor,
  canvasColor: AppColors.backgroundColor,
  appBarTheme: const AppBarTheme(
    color: AppColors.primaryColor,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: AppColors.textColor,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: AppColors.primaryColor,
      textStyle: const TextStyle(fontSize: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

);
