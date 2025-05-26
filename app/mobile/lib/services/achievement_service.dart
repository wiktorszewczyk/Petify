import 'package:dio/dio.dart';
import '../models/achievement.dart';
import '../models/basic_response.dart';
import '../models/level_info.dart';
import 'api/initial_api.dart';
import 'token_repository.dart';

class AchievementService {
  final _api = InitialApi().dio;
  static AchievementService? _instance;
  factory AchievementService() => _instance ??= AchievementService._();
  AchievementService._();

  /// Pobiera listę wszystkich osiągnięć użytkownika
  Future<List<Achievement>> getUserAchievements() async {
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
  }

  /// Pobiera informacje o poziomie, punktach XP i statystykach
  Future<LevelInfo> getUserLevelInfo() async {
    try {
      final resp = await _api.get('/user/achievements/level');
      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        return LevelInfo.fromJson(resp.data as Map<String, dynamic>);
      }
      throw Exception('Nieoczekiwana odpowiedź serwera');
    } on DioException catch (e) {
      throw Exception('Błąd podczas pobierania informacji o poziomie: ${e.message}');
    }
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
        return Achievement.fromJson(resp.data as Map<String, dynamic>);
      }
      throw Exception('Nieoczekiwana odpowiedź serwera');
    } on DioException catch (e) {
      throw Exception('Błąd podczas aktualizacji postępu: ${e.message}');
    }
  }
}