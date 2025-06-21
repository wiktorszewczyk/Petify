import 'dart:async';
import 'dart:developer' as dev;

class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final DateTime expiresAt;

  CacheEntry(this.data, Duration ttl)
      : createdAt = DateTime.now(),
        expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isStale => DateTime.now().isAfter(createdAt.add(Duration(minutes: 5)));

  Duration get timeToLive => expiresAt.difference(DateTime.now());
}

class CacheManager {
  static final Map<String, CacheEntry> _cache = {};
  static final Map<String, Future> _pendingRequests = {};

  /// Pobiera dane z cache'a, null jeśli nie ma lub wygasł
  static T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    dev.log('Cache HIT: $key (TTL: ${entry.timeToLive.inMinutes}min)');
    return entry.data as T?;
  }

  /// Zapisuje dane do cache'a z określonym TTL (auto-optymalizowane TTL)
  static void set<T>(String key, T data, {Duration? ttl}) {
    // Inteligentne TTL na podstawie typu danych
    ttl ??= _getOptimalTTL(key);

    _cache[key] = CacheEntry<T>(data, ttl);
    dev.log('Cache SET: $key (TTL: ${ttl.inMinutes}min)');
  }

  /// Określa optymalny TTL na podstawie klucza cache
  static Duration _getOptimalTTL(String key) {
    if (key.contains('pets') || key.contains('favorites')) {
      return Duration(minutes: 15); // Zwierzęta się rzadko zmieniają
    } else if (key.contains('user') || key.contains('achievements')) {
      return Duration(minutes: 20); // Dane użytkownika stabilne
    } else if (key.contains('events') || key.contains('posts')) {
      return Duration(minutes: 8); // Wydarzenia i posty częściej się zmieniają
    } else if (key.contains('conversations') || key.contains('messages')) {
      return Duration(minutes: 5); // Wiadomości szybko się zmieniają
    } else if (key.contains('reservations') || key.contains('slots')) {
      return Duration(minutes: 3); // Rezerwacje zmieniają się często
    } else {
      return Duration(minutes: 10); // Domyślne TTL
    }
  }

  /// Sprawdza czy dane są w cache ale już stare (potrzebują odświeżenia w tle)
  static bool isStale(String key) {
    final entry = _cache[key];
    return entry?.isStale == true;
  }

  /// Usuwa konkretny klucz z cache'a
  static void invalidate(String key) {
    _cache.remove(key);
    dev.log('Cache INVALIDATE: $key');
  }

  /// Usuwa wszystkie klucze pasujące do wzorca
  static void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    dev.log('Cache INVALIDATE_PATTERN: $pattern (removed ${keysToRemove.length} entries)');
  }

  /// Czyści cały cache
  static void clear() {
    final count = _cache.length;
    _cache.clear();
    _pendingRequests.clear();
    dev.log('Cache CLEAR: removed $count entries');
  }

  /// Zapobiega duplikowanym zapytaniom - jeśli to samo zapytanie jest już w toku,
  /// zwraca to samo Future
  static Future<T> deduplicate<T>(String key, Future<T> Function() fetcher) async {
    if (_pendingRequests.containsKey(key)) {
      dev.log('Request DEDUPLICATION: $key');
      return await _pendingRequests[key] as T;
    }

    final future = fetcher();
    _pendingRequests[key] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  /// Zwraca statystyki cache'a
  static Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final expired = _cache.values.where((entry) => entry.isExpired).length;
    final stale = _cache.values.where((entry) => entry.isStale && !entry.isExpired).length;
    final fresh = _cache.length - expired - stale;

    return {
      'total_entries': _cache.length,
      'fresh': fresh,
      'stale': stale,
      'expired': expired,
      'pending_requests': _pendingRequests.length,
    };
  }

  /// Automatyczne czyszczenie wygasłych wpisów (wywoływane okresowo)
  static void cleanup() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      dev.log('Cache CLEANUP: removed ${expiredKeys.length} expired entries');
    }
  }
}

/// Mixin dla serwisów, który dodaje funkcjonalność cache'owania
mixin CacheableMixin {
  /// Standardowy wzorzec: sprawdź cache, jeśli nie ma to pobierz i zapisz
  Future<T> cachedFetch<T>(
      String key,
      Future<T> Function() fetcher, {
        Duration? ttl,
        bool forceRefresh = false,
      }) async {
    if (!forceRefresh) {
      final cached = CacheManager.get<T>(key);
      if (cached != null) {
        // Jeśli dane są stale, odśwież w tle
        if (CacheManager.isStale(key)) {
          _refreshInBackground(key, fetcher, ttl);
        }
        return cached;
      }
    }

    // Zapobiegnij duplikowanym zapytaniom
    return await CacheManager.deduplicate<T>(key, () async {
      final data = await fetcher();
      CacheManager.set(key, data, ttl: ttl);
      return data;
    });
  }

  /// Odśwież dane w tle bez wpływu na UI
  void _refreshInBackground<T>(String key, Future<T> Function() fetcher, Duration? ttl) {
    fetcher().then((data) {
      CacheManager.set(key, data, ttl: ttl);
      dev.log('Background refresh completed: $key');
    }).catchError((error) {
      dev.log('Background refresh failed: $key - $error');
    });
  }

  /// Generuje unikalny klucz cache'a na podstawie parametrów
  String generateCacheKey(String prefix, Map<String, dynamic> params) {
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');
    return '${prefix}_$paramString';
  }
}