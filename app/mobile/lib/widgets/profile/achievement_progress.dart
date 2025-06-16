import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../styles/colors.dart';

class AchievementProgress extends StatelessWidget {
  final int level;
  final int xpPoints;
  final int xpToNextLevel;

  const AchievementProgress({
    Key? key,
    required this.level,
    required this.xpPoints,
    required this.xpToNextLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int xpRequiredForNextLevel = level * 100;
    final int xpEarnedThisLevel = xpRequiredForNextLevel - xpToNextLevel;
    final double progressPercent =
        xpEarnedThisLevel / xpRequiredForNextLevel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF9F5FF), Color(0xFFEFE6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek z poziomem i XP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Poziom $level',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$xpPoints XP',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tu używamy LinearPercentIndicator
            LinearPercentIndicator(
              animation: true,
              animationDuration: 800,
              lineHeight: 12,
              percent: progressPercent.clamp(0.0, 1.0),
              barRadius: const Radius.circular(8),
              progressColor: AppColors.primaryColor,
              backgroundColor: Colors.grey[300]!,
            ),

            const SizedBox(height: 8),

            // Opis postępu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Postęp',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${xpToNextLevel} XP do następnego poziomu',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }
}
