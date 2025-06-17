import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import '../pet_service.dart';
import '../feed_service.dart';
import '../message_service.dart';
import '../cache/cache_manager.dart';

/// Tracker zachowań użytkownika do predykcyjnego ładowania danych
class BehaviorTracker {
  static final BehaviorTracker _instance = BehaviorTracker._internal();
  factory BehaviorTracker() => _instance;
  BehaviorTracker._internal();

  static const String _prefKey = 'user_behavior_data';

  Timer? _saveTimer;
  UserBehavior _behavior = UserBehavior();

  Future<void> initialize() async {
    await _loadBehavior();
    _startPeriodicSave();
  }

  void trackScreenVisit(String screenName) {
    final now = DateTime.now();
    _behavior.screenVisits[screenName] = (_behavior.screenVisits[screenName] ?? 0) + 1;
    _behavior.lastScreenVisit[screenName] = now;

    dev.log('📊 Screen visit tracked: $screenName (${_behavior.screenVisits[screenName]} times)');

    _triggerPredictiveLoading(screenName);
  }

  void trackPetLike(int petId) {
    _behavior.likedPets.add(petId);
    _behavior.lastPetInteraction = DateTime.now();

    dev.log('📊 Pet like tracked: $petId');
  }

  void trackPetView(int petId) {
    _behavior.viewedPets.add(petId);
    _behavior.lastPetInteraction = DateTime.now();

    dev.log('📊 Pet view tracked: $petId');
  }

  void trackMessageActivity() {
    _behavior.messageInteractions++;
    _behavior.lastMessageActivity = DateTime.now();

    dev.log('📊 Message activity tracked');
  }

  void trackPetFiltering(Map<String, dynamic> filters) {
    _behavior.filterUsageCount++;
    _behavior.lastFilterUsage = DateTime.now();

    dev.log('📊 Pet filtering tracked');
  }

  void _triggerPredictiveLoading(String currentScreen) {
    _predictiveLoadInBackground(currentScreen);
  }

  void _predictiveLoadInBackground(String currentScreen) async {
    try {
      switch (currentScreen) {
        case 'home':
          await _preloadForHomeScreen();
          break;
        case 'favorites':
          await _preloadForFavoritesScreen();
          break;
        case 'profile':
          await _preloadForProfileScreen();
          break;
        case 'messages':
          await _preloadForMessagesScreen();
          break;
        case 'community':
          await _preloadForCommunityScreen();
          break;
      }
    } catch (e) {
      dev.log('Predictive loading failed for $currentScreen: $e');
    }
  }

  Future<void> _preloadForHomeScreen() async {
    if (isFrequentFavoritesUser) {
      PetService().getFavoritePets().catchError((_) {});
    }

    if (isFrequentFilterUser) {
      PetService().getPetsWithDefaultFilters().catchError((_) {});
    }

    _preloadNextPets();
  }

  Future<void> _preloadForFavoritesScreen() async {
    final favorites = CacheManager.get<List>('favorites_pets');
    if (favorites != null) {
      for (int i = 0; i < 5 && i < favorites.length; i++) {
        PetService().getPetById(favorites[i].id).catchError((_) {});
      }
    }
  }

  Future<void> _preloadForProfileScreen() async {
    if (hasRecentAchievementActivity) {
    }
  }

  Future<void> _preloadForMessagesScreen() async {
    if (isActiveMessageUser) {
      MessageService().getConversations().catchError((_) {});
    }
  }

  Future<void> _preloadForCommunityScreen() async {
    FeedService().getIncomingEvents(30).catchError((_) {});
  }

  void _preloadNextPets() async {
    if (isFastBrowser) {
      PetService().getPetsWithDefaultFilters().catchError((_) {});
    }
  }

  bool get isFrequentFavoritesUser =>
      (_behavior.screenVisits['favorites'] ?? 0) > 5;

  bool get isFrequentFilterUser =>
      _behavior.filterUsageCount > 3;

  bool get isActiveMessageUser =>
      _behavior.messageInteractions > 5;

  bool get isFastBrowser =>
      (_behavior.screenVisits['home'] ?? 0) > 10;

  bool get hasRecentAchievementActivity =>
      _behavior.lastScreenVisit['profile']?.isAfter(
          DateTime.now().subtract(Duration(hours: 24))
      ) ?? false;

  Future<void> _loadBehavior() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_prefKey);

      if (data != null) {
        _behavior = UserBehavior.fromJson(data);
        dev.log('📊 User behavior loaded: ${_behavior.summary}');
      }
    } catch (e) {
      dev.log('Failed to load user behavior: $e');
    }
  }

  Future<void> _saveBehavior() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _behavior.toJson());
      dev.log('📊 User behavior saved');
    } catch (e) {
      dev.log('Failed to save user behavior: $e');
    }
  }

  /// Uruchamia okresowe zapisywanie
  void _startPeriodicSave() {
    _saveTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _saveBehavior();
    });
  }

  void reset() {
    _behavior = UserBehavior();
    _saveBehavior();
    dev.log('📊 User behavior reset');
  }

  void dispose() {
    _saveTimer?.cancel();
    _saveBehavior(); // Final save
  }

  Map<String, dynamic> getInsights() {
    return {
      'total_screen_visits': _behavior.screenVisits.values.fold(0, (a, b) => a + b),
      'favorite_screen': _behavior.getMostVisitedScreen(),
      'is_frequent_favorites_user': isFrequentFavoritesUser,
      'is_active_message_user': isActiveMessageUser,
      'is_frequent_filter_user': isFrequentFilterUser,
      'pets_liked': _behavior.likedPets.length,
      'pets_viewed': _behavior.viewedPets.length,
    };
  }
}

class UserBehavior {
  Map<String, int> screenVisits = {};
  Map<String, DateTime> lastScreenVisit = {};
  Set<int> likedPets = {};
  Set<int> viewedPets = {};
  int messageInteractions = 0;
  int filterUsageCount = 0;
  DateTime? lastPetInteraction;
  DateTime? lastMessageActivity;
  DateTime? lastFilterUsage;

  UserBehavior();

  factory UserBehavior.fromJson(String jsonStr) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      final behavior = UserBehavior();

      if (json['screenVisits'] is Map) {
        behavior.screenVisits = Map<String, int>.from(json['screenVisits']);
      }

      if (json['likedPets'] is List) {
        behavior.likedPets = Set<int>.from(json['likedPets']);
      }

      if (json['viewedPets'] is List) {
        behavior.viewedPets = Set<int>.from(json['viewedPets']);
      }

      behavior.messageInteractions = json['messageInteractions'] ?? 0;
      behavior.filterUsageCount = json['filterUsageCount'] ?? 0;

      return behavior;
    } catch (e) {
      dev.log('Failed to parse UserBehavior JSON: $e');
      return UserBehavior();
    }
  }

  String toJson() {
    try {
      final Map<String, dynamic> json = {
        'screenVisits': screenVisits,
        'likedPets': likedPets.toList(),
        'viewedPets': viewedPets.toList(),
        'messageInteractions': messageInteractions,
        'filterUsageCount': filterUsageCount,
        'lastPetInteraction': lastPetInteraction?.toIso8601String(),
        'lastMessageActivity': lastMessageActivity?.toIso8601String(),
        'lastFilterUsage': lastFilterUsage?.toIso8601String(),
      };

      return jsonEncode(json);
    } catch (e) {
      dev.log('Failed to serialize UserBehavior: $e');
      return '{}';
    }
  }

  String get summary {
    final totalVisits = screenVisits.values.fold(0, (a, b) => a + b);
    return 'Total visits: $totalVisits, Liked pets: ${likedPets.length}, Messages: $messageInteractions';
  }

  String? getMostVisitedScreen() {
    if (screenVisits.isEmpty) return null;

    return screenVisits.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}