import 'package:flutter/material.dart';
import 'colors.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor,
    primary: AppColors.primaryColor,
    secondary: AppColors.primaryColor,
    surface: AppColors.backgroundColor,
    background: AppColors.backgroundColor,
  ),
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
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    labelStyle: const TextStyle(color: AppColors.primaryColor),
    floatingLabelStyle: const TextStyle(color: AppColors.primaryColor),
    prefixIconColor: AppColors.primaryColor,
    suffixIconColor: AppColors.primaryColor,
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: AppColors.primaryColor,
    selectionColor: AppColors.primaryColor.withOpacity(0.3),
    selectionHandleColor: AppColors.primaryColor,
  ),
  iconTheme: const IconThemeData(
    color: AppColors.primaryColor,
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.primaryColor;
      }
      return Colors.transparent;
    }),
    checkColor: MaterialStateProperty.all(Colors.white),
  ),
  radioTheme: RadioThemeData(
    fillColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.primaryColor;
      }
      return Colors.grey;
    }),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.primaryColor;
      }
      return Colors.grey;
    }),
    trackColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.primaryColor.withOpacity(0.5);
      }
      return Colors.grey.withOpacity(0.5);
    }),
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
