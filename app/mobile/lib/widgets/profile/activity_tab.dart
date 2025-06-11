import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../widgets/buttons/text_button.dart';
import '../../styles/colors.dart';

class ActivityTab extends StatelessWidget {
  final User user;

  const ActivityTab({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activities = user.recentActivities ?? [];

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/no_activity.png',
              height: 150,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak aktywności',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Zacznij przeglądać zwierzaki\naby zobaczyć swoją aktywność',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            CustomTextButton(
              text: 'Odkryj zwierzaki',
              icon: Icons.pets,
              onPressed: () {
                Navigator.pushNamed(context, '/discover');
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActivityIcon(activity['type']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getActivityTitle(activity),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity['timestamp'] ?? 'Niedawno',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (activity['points'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.secondaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${activity['points']}',
                        style: GoogleFonts.poppins(
                          color: AppColors.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (activity['description'] != null) ...[
            const SizedBox(height: 12),
            Text(
              activity['description'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
          if (activity['petImage'] != null || activity['petName'] != null) ...[
            const SizedBox(height: 12),
            _buildPetPreview(activity),
          ],
          if (activity['achievement'] != null) ...[
            const SizedBox(height: 12),
            _buildAchievementPreview(activity['achievement']),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityIcon(String? type) {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;

    switch (type) {
      case 'like':
        iconData = Icons.favorite;
        backgroundColor = Colors.red.withOpacity(0.1);
        iconColor = Colors.red;
        break;
      case 'donation':
        iconData = Icons.volunteer_activism;
        backgroundColor = AppColors.secondaryColor.withOpacity(0.1);
        iconColor = AppColors.secondaryColor;
        break;
      case 'achievement':
        iconData = Icons.emoji_events;
        backgroundColor = Colors.amber.withOpacity(0.1);
        iconColor = Colors.amber;
        break;
      case 'share':
        iconData = Icons.share;
        backgroundColor = Colors.blue.withOpacity(0.1);
        iconColor = Colors.blue;
        break;
      case 'visit':
        iconData = Icons.location_on;
        backgroundColor = Colors.green.withOpacity(0.1);
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.pets;
        backgroundColor = AppColors.primaryColor.withOpacity(0.1);
        iconColor = AppColors.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _getActivityTitle(Map<String, dynamic> activity) {
    switch (activity['type']) {
      case 'like':
        return 'Polubiłeś(aś) ${activity['petName'] ?? 'zwierzaka'}';
      case 'donation':
        return 'Wsparłeś(aś) schronisko ${activity['shelterName'] ?? ''}';
      case 'achievement':
        return 'Zdobyłeś(aś) osiągnięcie';
      case 'share':
        return 'Udostępniłeś(aś) ${activity['petName'] ?? 'zwierzaka'}';
      case 'visit':
        return 'Odwiedziłeś(aś) ${activity['shelterName'] ?? 'schronisko'}';
      default:
        return activity['title'] ?? 'Aktywność z Petify';
    }
  }

  Widget _buildPetPreview(Map<String, dynamic> activity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (activity['petImage'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                activity['petImage'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.pets, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['petName'] ?? 'Zwierzak',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (activity['petBreed'] != null)
                  Text(
                    activity['petBreed'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {
              // Navigate to pet details
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementPreview(Map<String, dynamic> achievement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['name'] ?? 'Nowe osiągnięcie',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (achievement['description'] != null)
                  Text(
                    achievement['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}