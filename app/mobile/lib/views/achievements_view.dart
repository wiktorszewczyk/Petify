import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../styles/colors.dart';
import '../widgets/badges/achievement_badge.dart';
import '../widgets/cards/achievement_card.dart';

class AchievementsView extends StatefulWidget {
  const AchievementsView({Key? key}) : super(key: key);

  @override
  State<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<AchievementsView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Achievement> _achievements = [];
  List<String> _categories = [];
  Map<String, List<Achievement>> _categorized = {};
  bool _isLoading = true;
  bool _isError = false;

  String _translateCategory(String cat) {
    switch (cat) {
      case 'LIKES':
        return 'Polubienia';
      case 'SUPPORT':
        return 'Wsparcia';
      case 'ADOPTION':
        return 'Adopcje';
      case 'PROFILE':
        return 'Profil';
      case 'VOLUNTEER':
        return 'Wolontariat';
      default:
        return cat;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    try {
      final list = await AchievementService().getUserAchievements();
      final cats = <String>{};
      for (var a in list) {
        cats.add(a.category);
      }
      final sortedCats = cats.toList()..sort();

      final allCats = [
        'Wszystkie',
        'Zdobyte',
        'Do zdobycia',
        ...sortedCats,
      ];

      final map = <String, List<Achievement>>{};
      map['Wszystkie'] = list;
      map['Zdobyte'] = list.where((a) => a.isUnlocked).toList();
      map['Do zdobycia'] = list.where((a) => !a.isUnlocked).toList();
      for (var cat in sortedCats) {
        map[cat] = list.where((a) => a.category == cat).toList();
      }

      _tabController = TabController(length: allCats.length, vsync: this);

      setState(() {
        _achievements = list;
        _categories = allCats;
        _categorized = map;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Twoje osiągnięcia')),
        body: Center(
          child: ElevatedButton(
            onPressed: _loadAchievements,
            child: const Text('Spróbuj ponownie'),
          ),
        ),
      );
    }

    final total = _achievements.length;
    final unlocked = _achievements.where((a) => a.isUnlocked).length;
    final xp = _achievements
        .where((a) => a.isUnlocked)
        .fold<int>(0, (sum, a) => sum + a.experiencePoints);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Twoje osiągnięcia',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle:
          GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
          GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 14),
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.textColor,
          indicatorColor: AppColors.white,
          tabs: _categories.map((c) => Tab(text: _translateCategory(c))).toList(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    Icons.emoji_events,
                    Colors.amber,
                    '$unlocked/$total',
                    'Zdobyte'),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                _buildStatItem(Icons.star, AppColors.primaryColor,
                    '$xp XP', 'Doświadczenie'),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                _buildStatItem(
                    Icons.trending_up,
                    Colors.green,
                    '${(unlocked / total * 100).toStringAsFixed(0)}%',
                    'Ukończone'),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                final list = _categorized[cat]!;
                return _buildGrid(list, cat);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, Color color, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style:
            GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildGrid(List<Achievement> items, String category) {
    if (category == 'Wszystkie') {
      items.sort((a, b) {
        if (a.isUnlocked != b.isUnlocked) return a.isUnlocked ? -1 : 1;
        if (a.isUnlocked) {
          return b.dateAchieved!.compareTo(a.dateAchieved!);
        }
        return 0;
      });
    } else if (category == 'Zdobyte') {
      items.sort((a, b) => b.dateAchieved!.compareTo(a.dateAchieved!));
    } else if (category == 'Do zdobycia') {
      items.sort((a, b) =>
          b.progressPercentage.compareTo(a.progressPercentage));
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Brak osiągnięć w tej kategorii',
                style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final ach = items[idx];
        return AchievementCard(
          achievement: ach,
          onTap: () => _showDetails(ach),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 50.ms * idx)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
      },
    );
  }

  void _showDetails(Achievement a) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AchievementBadge(achievement: a, size: 100),
                const SizedBox(height: 16),
                Text(a.title,
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(a.description,
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                if (!a.isUnlocked)
                  Text(
                    'Postęp: ${a.progressCurrent}/${a.progressTotal}',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[700]),
                  ),
                if (!a.isUnlocked)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(
                      value: a.progressPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
                    ),
                  ),
                if (a.isUnlocked && a.dateAchieved != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.date_range, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Zdobyto: ${a.dateAchieved!.day}.${a.dateAchieved!.month}.${a.dateAchieved!.year}',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: a.isUnlocked
                        ? AppColors.primaryColor.withOpacity(0.2)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('+${a.experiencePoints} XP',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.close, size: 18),
                      SizedBox(width: 8),
                      Text('Zamknij'),
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
}