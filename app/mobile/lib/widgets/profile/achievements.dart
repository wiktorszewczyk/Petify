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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NAGŁÓWEK Z PRZYCISKIEM
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
                    MaterialPageRoute(
                        builder: (_) => const AchievementsView()),
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

          // JEŚLI BRAK ZDOBYTYCH — placeholder zachęcający
          if (achievements.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Nie masz jeszcze żadnych odblokowanych odznak.\n'
                    'Wykonaj jakąś akcję, by zdobyć swoje pierwsze osiągnięcie!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: CustomTextButton(
                text: 'Zdobądź pierwsze osiągnięcie',
                icon: Icons.emoji_events_outlined,
                onPressed: () {
                  // Możesz tu zasugerować jakąś konkretną akcję
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                        Text('Spróbuj polubić jakieś zwierzę lub wesprzeć schronisko!')),
                  );
                },
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ] else ...[
            // W PRZECIWNYM RAZIE pozioma lista
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: achievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final a = achievements[index];
                  return AchievementBadge(
                    achievement: a,
                    onTap: () => _showAchievementDetails(context, a),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  void _showAchievementDetails(
      BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circle with icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.isUnlocked
                      ? AppColors.primaryColor.withOpacity(0.2)
                      : Colors.grey[300],
                ),
                child: Center(
                  child: Icon(
                    achievement.icon,
                    size: 40,
                    color: achievement.isUnlocked
                        ? AppColors.primaryColor
                        : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                achievement.title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                achievement.description,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Date achieved (jeśli dostępne)
              if (achievement.dateAchieved != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.date_range,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Zdobyto: ${_formatDate(achievement.dateAchieved!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // XP badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: achievement.isUnlocked
                      ? AppColors.primaryColor.withOpacity(0.2)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${achievement.experiencePoints} XP',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: achievement.isUnlocked
                        ? AppColors.primaryColor
                        : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Zamknij
              CustomTextButton(
                text: 'Zamknij',
                icon: Icons.close,
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.grey[200]!,
                foregroundColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date;
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }
}