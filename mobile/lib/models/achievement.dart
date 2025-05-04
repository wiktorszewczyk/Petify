import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final DateTime dateAchieved;
  final int experiencePoints;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isUnlocked;
  final String? category;
  final int? progressCurrent;
  final int? progressTotal;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.dateAchieved,
    required this.experiencePoints,
    this.iconColor,
    this.backgroundColor,
    this.isUnlocked = true,
    this.category,
    this.progressCurrent,
    this.progressTotal,
  });

  double get progressPercentage {
    if (progressCurrent == null || progressTotal == null || progressTotal == 0) {
      return isUnlocked ? 1.0 : 0.0;
    }
    return progressCurrent! / progressTotal!;
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    DateTime? dateAchieved,
    int? experiencePoints,
    Color? iconColor,
    Color? backgroundColor,
    bool? isUnlocked,
    String? category,
    int? progressCurrent,
    int? progressTotal,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      dateAchieved: dateAchieved ?? this.dateAchieved,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      iconColor: iconColor ?? this.iconColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      category: category ?? this.category,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTotal: progressTotal ?? this.progressTotal,
    );
  }

  // Factory constructor for locked/unachieved achievements
  factory Achievement.locked({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required int experiencePoints,
    Color? iconColor,
    Color? backgroundColor,
    String? category,
    int? progressCurrent,
    int? progressTotal,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      // Use a future date as placeholder for locked achievements
      dateAchieved: DateTime(9999),
      experiencePoints: experiencePoints,
      iconColor: iconColor ?? Colors.grey,
      backgroundColor: backgroundColor ?? Colors.grey[200],
      isUnlocked: false,
      category: category,
      progressCurrent: progressCurrent,
      progressTotal: progressTotal,
    );
  }
}