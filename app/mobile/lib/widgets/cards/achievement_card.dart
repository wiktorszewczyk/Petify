import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/achievement.dart';
import '../../styles/colors.dart';
import '../badges/achievement_badge.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    Key? key,
    required this.achievement,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = achievement.isUnlocked
        ? AppColors.primaryColor.withOpacity(0.3)
        : Colors.grey[300]!;

    final xpBadgeBg = achievement.isUnlocked
        ? AppColors.primaryColor.withOpacity(0.1)
        : Colors.grey[200];

    final xpBadgeColor = achievement.isUnlocked
        ? AppColors.primaryColor
        : Colors.grey[600];

    return Card(
      elevation: achievement.isUnlocked ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Odznaka
              AchievementBadge(
                achievement: achievement,
                size: 50,
              ),
              const SizedBox(height: 6),
              // Tytuł
              Text(
                achievement.title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: achievement.isUnlocked
                      ? Colors.black87
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // XP badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: xpBadgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${achievement.experiencePoints} XP',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: xpBadgeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}