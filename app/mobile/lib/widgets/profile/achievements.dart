import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/achievement.dart';
import '../../styles/colors.dart';
import '../../widgets/badges/achievement_badge.dart';
import '../../widgets/buttons/text_button.dart';
import '../../views/achievements_view.dart';

class Achievements extends StatelessWidget {
  final List<Achievement> achievements;

  const Achievements({
    Key? key,
    required this.achievements,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Zdobyte osiągnięcia',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AchievementsView()),
                  );
                },
                child: Text(
                  'Zobacz wszystkie',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < achievements.length - 1 ? 16 : 0,
                  ),
                  child: AchievementBadge(
                    achievement: achievement,
                    onTap: () {
                      _showAchievementDetails(context, achievement);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.backgroundColor ?? AppColors.primaryColor.withOpacity(0.2),
                ),
                child: Icon(
                  achievement.icon,
                  size: 40,
                  color: achievement.iconColor ?? AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 16),
              Text(
                achievement.title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                achievement.description,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Zdobyto: ${_formatDate(achievement.dateAchieved)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${achievement.experiencePoints} XP',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              SizedBox(height: 24),
              CustomTextButton(
                text: 'Zamknij',
                icon: Icons.close,
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}