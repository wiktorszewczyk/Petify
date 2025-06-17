import 'dart:async';
import 'dart:developer' as dev;
import 'cache_manager.dart';

/// Scheduler odpowiedzialny za automatyczne czyszczenie cache'a i statystyki
class CacheScheduler {
  static Timer? _cleanupTimer;
  static Timer? _statsTimer;
  static bool _isRunning = false;

  /// Startuje automatyczne czyszczenie co 2 minuty
  static void start() {
    if (_isRunning) return;

    _isRunning = true;

    // Czyszczenie wygasłych wpisów co 2 minuty
    _cleanupTimer = Timer.periodic(Duration(minutes: 2), (_) {
      CacheManager.cleanup();
    });

    // Logowanie statystyk co 5 minut (tylko w debug mode)
    _statsTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _logStats();
    });

    dev.log('CacheScheduler started');
  }

  /// Zatrzymuje scheduler
  static void stop() {
    _cleanupTimer?.cancel();
    _statsTimer?.cancel();
    _cleanupTimer = null;
    _statsTimer = null;
    _isRunning = false;
    dev.log('CacheScheduler stopped');
  }

  /// Loguje statystyki cache'a
  static void _logStats() {
    final stats = CacheManager.getStats();
    dev.log('Cache Stats: ${stats.toString()}');
  }

  /// Sprawdza czy scheduler jest uruchomiony
  static bool get isRunning => _isRunning;
}