import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/achievement.dart';
import '../styles/colors.dart';
import '../widgets/badges/achievement_badge.dart';

class AchievementsView extends StatefulWidget {
  const AchievementsView({Key? key}) : super(key: key);

  @override
  State<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<AchievementsView> with TickerProviderStateMixin {
  late TabController _tabController;
  late List<Achievement> _achievements;
  late List<String> _categories;

  late Map<String, List<Achievement>> _categorizedAchievements;

  @override
  void initState() {
    super.initState();
    _loadAchievements();

    _categories = [
      'Wszystkie',
      'Zdobyte',
      'Do zdobycia',
      ..._getCategoriesFromAchievements()
    ];

    _tabController = TabController(length: _categories.length, vsync: this);
  }

  void _loadAchievements() {
    // TODO: Połączyć z backendem i pobrać prawdziwe osiągniecia do zdobycia
    _achievements = [
      Achievement(
        id: '1',
        title: 'Pierwsze wsparcie',
        description: 'Wspomogłeś pierwsze zwierzę',
        icon: Icons.volunteer_activism,
        dateAchieved: DateTime.now().subtract(const Duration(days: 5)),
        experiencePoints: 50,
        iconColor: Colors.blue,
        category: 'Wsparcia',
      ),
      Achievement(
        id: '2',
        title: 'Miłośnik zwierząt',
        description: 'Polubiłeś 10 profili zwierząt',
        icon: Icons.favorite,
        dateAchieved: DateTime.now().subtract(const Duration(days: 3)),
        experiencePoints: 30,
        iconColor: Colors.red,
        category: 'Polubienia',
      ),
      Achievement(
        id: '3',
        title: 'Szczodry darczyńca',
        description: 'Przekazałeś łącznie 1000 zł na wsparcie zwierząt',
        icon: Icons.attach_money,
        dateAchieved: DateTime.now().subtract(const Duration(days: 1)),
        experiencePoints: 100,
        iconColor: Colors.green,
        category: 'Wsparcia',
      ),
      Achievement.locked(
        id: '4',
        title: 'Złoty samarytanin',
        description: 'Wesprzyj 50 zwierząt',
        icon: Icons.workspace_premium,
        experiencePoints: 500,
        iconColor: Colors.amber,
        category: 'Wsparcia',
        progressCurrent: 12,
        progressTotal: 50,
      ),
      Achievement.locked(
        id: '5',
        title: 'Społeczny aktywista',
        description: 'Udostępnij 20 profili w mediach społecznościowych',
        icon: Icons.share,
        experiencePoints: 200,
        iconColor: Colors.purple,
        category: 'Społeczność',
        progressCurrent: 5,
        progressTotal: 20,
      ),
    ];

    _categorizeAchievements();
  }

  List<String> _getCategoriesFromAchievements() {
    final categories = _achievements
        .map((a) => a.category ?? 'Inne')
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  void _categorizeAchievements() {
    _categorizedAchievements = {
      'Wszystkie': _achievements,
      'Zdobyte': _achievements.where((a) => a.isUnlocked).toList(),
      'Do zdobycia': _achievements.where((a) => !a.isUnlocked).toList(),
    };

    for (final achievement in _achievements) {
      final category = achievement.category ?? 'Inne';
      if (!_categorizedAchievements.containsKey(category)) {
        _categorizedAchievements[category] = [];
      }
      _categorizedAchievements[category]!.add(achievement);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Twoje osiągnięcia',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.textColor,
          indicatorColor: AppColors.white,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildAchievementStats(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                final achievementsToShow = _categorizedAchievements[category] ?? [];
                return _buildAchievementGrid(achievementsToShow, category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementStats() {
    final totalAchievements = _achievements.length;
    final unlockedAchievements = _achievements.where((a) => a.isUnlocked).length;
    final totalXP = _achievements.where((a) => a.isUnlocked).fold<int>(
        0, (sum, achievement) => sum + achievement.experiencePoints);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              Icons.emoji_events,
              Colors.amber,
              '$unlockedAchievements/$totalAchievements',
              'Zdobyte'
          ),
          Container(height: 40, width: 1, color: Colors.grey[300]),
          _buildStatItem(
              Icons.star,
              AppColors.primaryColor,
              '$totalXP XP',
              'Doświadczenie'
          ),
          Container(height: 40, width: 1, color: Colors.grey[300]),
          _buildStatItem(
              Icons.trending_up,
              Colors.green,
              '${(unlockedAchievements / totalAchievements * 100).toStringAsFixed(0)}%',
              'Ukończone'
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementGrid(List<Achievement> achievements, String category) {
    if (category == 'Wszystkie') {
      achievements.sort((a, b) {
        if (a.isUnlocked != b.isUnlocked) {
          return a.isUnlocked ? -1 : 1;
        }
        if (a.isUnlocked && b.isUnlocked) {
          return b.dateAchieved.compareTo(a.dateAchieved);
        }
        return 0;
      });
    } else if (category == 'Zdobyte') {
      achievements.sort((a, b) => b.dateAchieved.compareTo(a.dateAchieved));
    } else if (category == 'Do zdobycia') {
      achievements.sort((a, b) {
        if (a.progressPercentage != b.progressPercentage) {
          return b.progressPercentage.compareTo(a.progressPercentage);
        }
        return a.title.compareTo(b.title);
      });
    }

    return achievements.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Brak osiągnięć w tej kategorii',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    )
        : GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return AchievementCard(
          achievement: achievement,
          onTap: () {
            _showAchievementDetails(context, achievement);
          },
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 50.ms * index)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
      },
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: achievement.isUnlocked
                            ? achievement.backgroundColor ?? AppColors.primaryColor.withOpacity(0.2)
                            : Colors.grey[300],
                        boxShadow: achievement.isUnlocked
                            ? [
                          BoxShadow(
                            color: (achievement.iconColor ?? AppColors.primaryColor).withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                            : null,
                      ),
                      child: Icon(
                        achievement.icon,
                        size: 50,
                        color: achievement.isUnlocked
                            ? achievement.iconColor ?? AppColors.primaryColor
                            : Colors.grey[600],
                      ),
                    ),

                    if (achievement.progressTotal != null &&
                        achievement.progressCurrent != null &&
                        !achievement.isUnlocked)
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: achievement.progressPercentage,
                          strokeWidth: 4,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.iconColor ?? AppColors.primaryColor,
                          ),
                        ),
                      ),

                    if (!achievement.isUnlocked)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: Icon(
                          Icons.lock,
                          size: 40,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  achievement.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.description,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                if (achievement.progressTotal != null &&
                    achievement.progressCurrent != null &&
                    !achievement.isUnlocked) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Postęp: ${achievement.progressCurrent}/${achievement.progressTotal}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: achievement.progressPercentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achievement.iconColor ?? AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (achievement.isUnlocked) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Zdobyto: ${_formatDate(achievement.dateAchieved)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // XP reward badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked
                        ? AppColors.primaryColor.withOpacity(0.2)
                        : Colors.grey[200],
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
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Zamknij',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

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
    return Card(
      elevation: achievement.isUnlocked ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: achievement.isUnlocked
              ? (achievement.iconColor ?? AppColors.primaryColor).withOpacity(0.3)
              : Colors.grey[300]!,
          width: 1,
        ),
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
              Flexible(
                child: AchievementBadge(
                  achievement: achievement,
                  size: 50,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  achievement.title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: achievement.isUnlocked ? Colors.black87 : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: achievement.isUnlocked
                      ? (achievement.iconColor ?? AppColors.primaryColor).withOpacity(0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${achievement.experiencePoints} XP',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: achievement.isUnlocked
                        ? achievement.iconColor ?? AppColors.primaryColor
                        : Colors.grey[600],
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