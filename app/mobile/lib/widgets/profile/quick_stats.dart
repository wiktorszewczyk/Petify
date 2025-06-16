import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user.dart';
import '../../widgets/cards/stats_card.dart';
import '../../styles/colors.dart';

class QuickStats extends StatelessWidget {
  final User user;

  const QuickStats({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              icon: Icons.favorite,
              iconColor: Colors.red,
              title: 'Polubione',
              // teraz z user.likesCount
              value: user.likesCount.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              icon: Icons.volunteer_activism,
              iconColor: Colors.blue,
              title: 'Wsparcia',
              // teraz z user.supportCount
              value: user.supportCount.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              icon: Icons.emoji_events,
              iconColor: Colors.amber,
              title: 'Odznaki',
              // teraz z user.badgesCount
              value: user.achievements
                  .where((a) => a.isUnlocked)
                  .length
                  .toString(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0);
  }
}