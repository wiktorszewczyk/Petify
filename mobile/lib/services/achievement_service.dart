import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementService {
  // Symulacja pobierania osiągnięć z API/bazy danych
  Future<List<Achievement>> getUserAchievements() async {
    // Symulacja czasu ładowania z serwera
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      Achievement(
        id: 'achievement_1',
        title: 'Pierwszy wpis',
        description: 'Utworzyłeś swój pierwszy wpis na platformie!',
        icon: Icons.article_outlined,
        dateAchieved: DateTime.now().subtract(const Duration(days: 2)),
        experiencePoints: 50,
        iconColor: Colors.blue,
        backgroundColor: Colors.blue.shade100,
        category: 'Podstawowe',
      ),
      Achievement(
        id: 'achievement_2',
        title: 'Pomocna dłoń',
        description: 'Wspierasz swoje pierwsze schronisko!',
        icon: Icons.volunteer_activism,
        dateAchieved: DateTime.now().subtract(const Duration(days: 5)),
        experiencePoints: 100,
        iconColor: Colors.green,
        backgroundColor: Colors.green.shade100,
        category: 'Wsparcie',
      ),
      Achievement(
        id: 'achievement_3',
        title: 'Szczodry darczyńca',
        description: 'Przekazałeś swoją pierwszą darowiznę!',
        icon: Icons.monetization_on,
        dateAchieved: DateTime.now().subtract(const Duration(days: 10)),
        experiencePoints: 150,
        iconColor: Colors.amber,
        backgroundColor: Colors.amber.shade100,
        category: 'Darowizny',
      ),
      Achievement.locked(
        id: 'achievement_4',
        title: 'Społeczna aktywność',
        description: 'Skontaktuj się z 5 różnymi schroniskami',
        icon: Icons.people_outlined,
        experiencePoints: 200,
        iconColor: Colors.purple,
        backgroundColor: Colors.purple.shade100,
        category: 'Społeczność',
        progressCurrent: 2,
        progressTotal: 5,
      ),
      Achievement.locked(
        id: 'achievement_5',
        title: 'Regularny darczyńca',
        description: 'Dokonaj wpłat przez 3 kolejne miesiące',
        icon: Icons.calendar_month,
        experiencePoints: 300,
        iconColor: Colors.orange,
        backgroundColor: Colors.orange.shade100,
        category: 'Darowizny',
        progressCurrent: 1,
        progressTotal: 3,
      ),
    ];
  }

  // Pobranie osiągnięć według kategorii
  Future<List<Achievement>> getAchievementsByCategory(String category) async {
    final allAchievements = await getUserAchievements();
    return allAchievements.where((a) => a.category == category).toList();
  }

  // Pobranie najnowszych osiągnięć
  Future<List<Achievement>> getRecentAchievements({int limit = 3}) async {
    final allAchievements = await getUserAchievements();

    // Sortowanie po dacie zdobycia - tylko odblokowane osiągnięcia
    final unlockedAchievements = allAchievements
        .where((a) => a.isUnlocked)
        .toList()
      ..sort((a, b) => b.dateAchieved.compareTo(a.dateAchieved));

    return unlockedAchievements.take(limit).toList();
  }

  // Odblokowanie nowego osiągnięcia
  Future<Achievement> unlockAchievement(String achievementId) async {
    final allAchievements = await getUserAchievements();
    final achievement = allAchievements.firstWhere((a) => a.id == achievementId);

    // W przypadku prawdziwej implementacji, tutaj byłoby wywołanie API
    // w celu odblokowania osiągnięcia na serwerze

    return achievement.copyWith(
      isUnlocked: true,
      dateAchieved: DateTime.now(),
    );
  }

  // Aktualizacja postępu osiągnięcia
  Future<Achievement> updateAchievementProgress(
      String achievementId,
      int currentProgress
      ) async {
    final allAchievements = await getUserAchievements();
    final achievement = allAchievements.firstWhere((a) => a.id == achievementId);

    final updatedAchievement = achievement.copyWith(
      progressCurrent: currentProgress,
    );

    // Sprawdzenie czy osiągnięcie powinno zostać odblokowane
    if (updatedAchievement.progressTotal != null &&
        currentProgress >= updatedAchievement.progressTotal!) {
      return updatedAchievement.copyWith(
        isUnlocked: true,
        dateAchieved: DateTime.now(),
      );
    }

    return updatedAchievement;
  }

  // Pobranie wszystkich kategorii osiągnięć
  Future<List<String>> getAchievementCategories() async {
    final achievements = await getUserAchievements();
    final categories = achievements
        .map((a) => a.category)
        .whereType<String>()
        .toSet()
        .toList();

    return categories;
  }

  // Pobranie sumy doświadczenia ze wszystkich odblokowanych osiągnięć
  Future<int> getTotalExperiencePoints() async {
    final achievements = await getUserAchievements();
    return achievements
        .where((a) => a.isUnlocked)
        .fold<int>(0, (sum, a) => sum + a.experiencePoints);
  }
}