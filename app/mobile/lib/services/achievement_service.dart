import 'package:dio/dio.dart';
import '../models/achievement.dart';
import '../models/basic_response.dart';
import '../models/level_info.dart';
import 'api/initial_api.dart';
import 'token_repository.dart';
import 'cache/cache_manager.dart';
import 'cache/cache_scheduler.dart';

class AchievementService with CacheableMixin {
  final _api = InitialApi().dio;
  static AchievementService? _instance;
  factory AchievementService() => _instance ??= AchievementService._();
  AchievementService._();

  /// Pobiera listę wszystkich osiągnięć użytkownika
  Future<List<Achievement>> getUserAchievements() async {
    const cacheKey = 'user_achievements';

    return cachedFetch(cacheKey, () async {
      try {
        final resp = await _api.get('/user/achievements/');
        if (resp.statusCode == 200 && resp.data is List) {
          return (resp.data as List)
              .cast<Map<String, dynamic>>()
              .map((j) => Achievement.fromJson(j))
              .toList();
        }
        throw Exception('Nieoczekiwana odpowiedź serwera');
      } on DioException catch (e) {
        throw Exception('Błąd podczas pobierania osiągnięć: ${e.message}');
      }
    }, ttl: Duration(minutes: 10));
  }

  /// Pobiera informacje o poziomie, punktach XP i statystykach
  Future<LevelInfo> getUserLevelInfo() async {
    const cacheKey = 'user_level_info';

    return cachedFetch(cacheKey, () async {
      try {
        final resp = await _api.get('/user/achievements/level');
        if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
          return LevelInfo.fromJson(resp.data as Map<String, dynamic>);
        }
        throw Exception('Nieoczekiwana odpowiedź serwera');
      } on DioException catch (e) {
        throw Exception('Błąd podczas pobierania informacji o poziomie: ${e.message}');
      }
    }, ttl: Duration(minutes: 15)); // Dłuższy TTL dla poziomu
  }

  /// Zgłasza przyrost postępu dla danego osiągnięcia
  Future<Achievement> trackAchievementProgress({
    required int achievementId,
    required int progressIncrement,
  }) async {
    try {
      final resp = await _api.post(
        '/user/achievements/$achievementId/progress',
        queryParameters: {'progress': progressIncrement},
      );

      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        // Invaliduj cache osiągnięć po aktualizacji postępu
        CacheManager.markStalePattern('user_achievements');
        CacheManager.markStalePattern('user_level');
        CacheManager.markStale('current_user'); // Poziom może się zmienić
        CacheScheduler.forceRefreshCriticalData();

        return Achievement.fromJson(resp.data as Map<String, dynamic>);
      }
      throw Exception('Nieoczekiwana odpowiedź serwera');
    } on DioException catch (e) {
      throw Exception('Błąd podczas aktualizacji postępu: ${e.message}');
    }
  }
}