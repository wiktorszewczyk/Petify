import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/achievement.dart';
import '../../styles/colors.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final double size;
  final bool showLabel;

  const AchievementBadge({
    Key? key,
    required this.achievement,
    this.onTap,
    this.size = 80,
    this.showLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: achievement.isUnlocked
                        ? achievement.backgroundColor ?? AppColors.primaryColor.withOpacity(0.2)
                        : Colors.grey[300],
                    boxShadow: achievement.isUnlocked
                        ? [
                      BoxShadow(
                        color: (achievement.iconColor ?? AppColors.primaryColor).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                        : null,
                    border: Border.all(
                      color: achievement.isUnlocked
                          ? (achievement.iconColor ?? AppColors.primaryColor).withOpacity(0.5)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                ),

                // Main icon
                Center(
                  child: Icon(
                    achievement.icon,
                    size: size * 0.45,
                    color: achievement.isUnlocked
                        ? achievement.iconColor ?? AppColors.primaryColor
                        : Colors.grey[600],
                  ),
                ),

                if (!achievement.isUnlocked)
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.lock,
                        size: size * 0.35,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),

                if (achievement.progressTotal != null &&
                    achievement.progressCurrent != null &&
                    !achievement.isUnlocked)
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: achievement.progressPercentage,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        achievement.iconColor ?? AppColors.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: achievement.isUnlocked ? Colors.black87 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}