import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final DateTime? dateAchieved;
  final int experiencePoints;
  final String category;
  final int progressCurrent;
  final int progressTotal;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.dateAchieved,
    required this.experiencePoints,
    required this.category,
    required this.progressCurrent,
    required this.progressTotal,
  });

  double get progressPercentage {
    if (isUnlocked) return 1.0;
    if (progressTotal <= 0) return 0.0;
    return progressCurrent / progressTotal;
  }

  factory Achievement.fromJson(Map<String, dynamic> j) {
    final ach = j['achievement'] as Map<String, dynamic>;

    IconData _iconFromName(String name) {
      switch (name) {
        case 'pet':
          return Icons.pets;
        case 'heart':
          return Icons.favorite;
        case 'hands-helping':
          return Icons.volunteer_activism;
        case 'money-bill':
          return Icons.attach_money;
        default:
          return Icons.emoji_events;
      }
    }

    return Achievement(
      id: j['id'].toString(),
      title: ach['name'] as String,
      description: ach['description'] as String,
      icon: _iconFromName(ach['iconName'] as String),
      isUnlocked: j['completed'] as bool,
      dateAchieved: j['completionDate'] != null
          ? DateTime.parse(j['completionDate'] as String)
          : null,
      experiencePoints: ach['xpReward'] as int,
      category: ach['category'] as String,
      progressCurrent: j['currentProgress'] as int,
      progressTotal: ach['requiredActions'] as int,
    );
  }
}