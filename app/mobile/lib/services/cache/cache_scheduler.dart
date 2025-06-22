import 'dart:async';
import 'dart:developer' as dev;
import 'cache_manager.dart';
import '../pet_service.dart';
import '../user_service.dart';
import '../achievement_service.dart';
import '../feed_service.dart';
import '../message_service.dart';

/// Enhanced scheduler odpowiedzialny za automatyczne czyszczenie cache'a, preloading i optymalizację
class CacheScheduler {
  static Timer? _cleanupTimer;
  static Timer? _statsTimer;
  static Timer? _preloadTimer;
  static bool _isRunning = false;

  /// Startuje enhanced cache management
  static void start() {
    if (_isRunning) return;

    _isRunning = true;

    // Czyszczenie wygasłych wpisów co 90 sekund dla lepszej wydajności
    _cleanupTimer = Timer.periodic(Duration(seconds: 90), (_) {
      CacheManager.cleanup();
    });

    // Inteligentny preloading co 3 minuty
    _preloadTimer = Timer.periodic(Duration(minutes: 3), (_) {
      _intelligentPreload();
    });

    // Logowanie statystyk co 5 minut (tylko w debug mode)
    _statsTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _logStats();
    });

    dev.log('🚀 Enhanced CacheScheduler started');
  }

  /// Zatrzymuje scheduler
  static void stop() {
    _cleanupTimer?.cancel();
    _statsTimer?.cancel();
    _preloadTimer?.cancel();
    _cleanupTimer = null;
    _statsTimer = null;
    _preloadTimer = null;
    _isRunning = false;
    dev.log('🛑 Enhanced CacheScheduler stopped');
  }

  /// Inteligentny preloading danych w tle
  static void _intelligentPreload() async {
    try {
      dev.log('🔄 Starting intelligent background preload...');

      // Lista zadań preloadingu (wykonywane równolegle)
      final preloadTasks = <Future>[];

      // 1. Odśwież dane użytkownika jeśli są stale
      if (CacheManager.isStale('current_user')) {
        preloadTasks.add(
            UserService().getCurrentUser().timeout(Duration(seconds: 5)).catchError((_) {})
        );
      }

      // 2. Odśwież zwierzęta jeśli są stale (sprawdzamy różne klucze cache)
      final petsKeys = ['pets_default', 'pets_default_filters'];
      bool shouldRefreshPets = false;
      for (final key in petsKeys) {
        if (CacheManager.isStale(key) || CacheManager.get(key) == null) {
          shouldRefreshPets = true;
          break;
        }
      }

      if (shouldRefreshPets) {
        preloadTasks.add(
            PetService().getPetsWithDefaultFilters(limit: 30).timeout(Duration(seconds: 8)).catchError((_) {})
        );
      }

      // 3. Preload osiągnięć jeśli są stale
      if (CacheManager.isStale('achievements_user')) {
        preloadTasks.add(
            AchievementService().getUserAchievements().timeout(Duration(seconds: 5)).catchError((_) {})
        );
      }

      // 4. Preload wydarzeń
      if (CacheManager.isStale('events_incoming_30') || CacheManager.get('events_incoming_30') == null) {
        preloadTasks.add(
            FeedService().getIncomingEvents(30).timeout(Duration(seconds: 6)).catchError((_) {})
        );
      }

      // 5. Preload wiadomości
      if (CacheManager.isStale('conversations') || CacheManager.get('conversations') == null) {
        preloadTasks.add(
            MessageService().getConversations().timeout(Duration(seconds: 4)).catchError((_) {})
        );
      }

      // Wykonaj wszystkie zadania równolegle z timeout
      if (preloadTasks.isNotEmpty) {
        await Future.wait(preloadTasks).timeout(Duration(seconds: 15));
        dev.log('✅ Intelligent preload completed (${preloadTasks.length} tasks)');
      } else {
        dev.log('✨ Cache is fresh, skipping preload');
      }

    } catch (e) {
      dev.log('⚠️ Intelligent preload failed: $e');
    }
  }

  /// Loguje statystyki cache'a
  static void _logStats() {
    final stats = CacheManager.getStats();
    dev.log('📊 Cache Stats: ${stats.toString()}');
  }

  /// Sprawdza czy scheduler jest uruchomiony
  static bool get isRunning => _isRunning;

  /// Force refresh krytycznych danych
  static Future<void> forceRefreshCriticalData() async {
    try {
      dev.log('🔥 Force refreshing critical data...');

      await Future.wait([
        UserService().getCurrentUser().timeout(Duration(seconds: 5)),
        PetService().getPetsWithDefaultFilters(limit: 20).timeout(Duration(seconds: 8)),
        AchievementService().getUserAchievements().timeout(Duration(seconds: 5)),
      ]).timeout(Duration(seconds: 12));

      dev.log('✅ Critical data refresh completed');
    } catch (e) {
      dev.log('❌ Critical data refresh failed: $e');
    }
  }
}