import 'dart:async';
import 'dart:developer' as dev;
import '../user_service.dart';
import '../pet_service.dart';
import '../achievement_service.dart';
import '../feed_service.dart';
import '../donation_service.dart';
import '../filter_preferences_service.dart';
import '../location_service.dart';
import '../application_service.dart';
import '../reservation_service.dart';
import '../message_service.dart';
import '../cache/cache_manager.dart';
import 'behavior_tracker.dart';

/// Inteligentny preloader aplikacji - ładuje kluczowe dane na starcie
class AppPreloader {
  static final AppPreloader _instance = AppPreloader._internal();
  factory AppPreloader() => _instance;
  AppPreloader._internal();

  bool _isPreloadingComplete = false;
  bool _isPreloadingInProgress = false;
  final List<String> _loadingSteps = [];
  final StreamController<PreloadProgress> _progressController = StreamController<PreloadProgress>.broadcast();

  Stream<PreloadProgress> get progressStream => _progressController.stream;

  bool get isComplete => _isPreloadingComplete;

  bool get isInProgress => _isPreloadingInProgress;

  Future<void> preloadEssentialData() async {
    if (_isPreloadingInProgress || _isPreloadingComplete) return;

    _isPreloadingInProgress = true;
    _isPreloadingComplete = false;
    _loadingSteps.clear();

    dev.log('🚀 Starting app preloading...');

    try {
      final steps = [
        PreloadStep('Logowanie użytkownika', _preloadUserData),
        PreloadStep('Ładowanie preferencji', _preloadUserPreferences),
        PreloadStep('Pobieranie zwierząt', _preloadPetsData),
        PreloadStep('Przygotowanie profilu', _preloadUserProfile),
        PreloadStep('Ładowanie wydarzeń', _preloadEventsData),
        PreloadStep('Finalizacja', _finalizePreload),
      ];

      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        final progress = PreloadProgress(
          currentStep: i + 1,
          totalSteps: steps.length,
          stepName: step.name,
          isComplete: false,
        );

        _progressController.add(progress);
        dev.log('📝 Step ${i + 1}/${steps.length}: ${step.name}');

        try {
          await step.action();
          _loadingSteps.add('✅ ${step.name}');
        } catch (e) {
          dev.log('⚠️ Step ${step.name} failed: $e');
          _loadingSteps.add('⚠️ ${step.name} (błąd)');
        }

        await Future.delayed(Duration(milliseconds: 200));
      }

      _isPreloadingComplete = true;
      _progressController.add(PreloadProgress(
        currentStep: steps.length,
        totalSteps: steps.length,
        stepName: 'Gotowe!',
        isComplete: true,
      ));

      dev.log('✅ App preloading completed successfully');
    } catch (e) {
      dev.log('❌ App preloading failed: $e');
      _isPreloadingComplete = true;
    } finally {
      _isPreloadingInProgress = false;
    }
  }

  /// Preload podstawowych danych użytkownika
  Future<void> _preloadUserData() async {
    try {
      await UserService().getCurrentUser();
      dev.log('User data preloaded');
    } catch (e) {
      dev.log('Failed to preload user data: $e');
    }
  }

  /// Preload preferencji użytkownika
  Future<void> _preloadUserPreferences() async {
    try {
      await FilterPreferencesService().getFilterPreferences();

      // Inicjalizuj behavior tracker
      await BehaviorTracker().initialize();

      dev.log('User preferences preloaded');
    } catch (e) {
      dev.log('Failed to preload user preferences: $e');
    }
  }

  /// Preload podstawowych danych o zwierzętach
  Future<void> _preloadPetsData() async {
    try {
      // Ładuj asynchronicznie z timeoutem
      await Future.wait([
        PetService().getPetsWithDefaultFilters().timeout(Duration(seconds: 10)),
        PetService().getFavoritePets().timeout(Duration(seconds: 8)),
      ]).timeout(Duration(seconds: 12));

      dev.log('Pets data preloaded');
    } catch (e) {
      dev.log('Failed to preload pets data: $e');
    }
  }

  /// Preload danych profilu użytkownika
  Future<void> _preloadUserProfile() async {
    try {
      await Future.wait([
        AchievementService().getUserAchievements().timeout(Duration(seconds: 8)),
        AchievementService().getUserLevelInfo().timeout(Duration(seconds: 6)),
        DonationService().getUserDonations().timeout(Duration(seconds: 6)),
        // Dodaj preload aplikacji adopcyjnych
        ApplicationService().getMyAdoptionApplications().timeout(Duration(seconds: 5)),
      ]).timeout(Duration(seconds: 12));

      dev.log('User profile data preloaded');
    } catch (e) {
      dev.log('Failed to preload user profile: $e');
    }
  }

  /// Preload danych wydarzeń
  Future<void> _preloadEventsData() async {
    try {
      await FeedService().getIncomingEvents(30).timeout(Duration(seconds: 6));
      dev.log('Events data preloaded');
    } catch (e) {
      dev.log('Failed to preload events data: $e');
    }
  }

  /// Finalizuj preloading
  Future<void> _finalizePreload() async {
    CacheManager.cleanup();

    LocationService().getCurrentLocation().catchError((e) {
      dev.log('Background location fetch failed: $e');
    });

    dev.log('Preloading finalized');
  }

  /// Inteligentny predictive preload - ładuje dane na podstawie zachowań użytkownika
  Future<void> predictivePreload() async {
    if (!_isPreloadingComplete) return;

    dev.log('🔮 Starting predictive preloading...');

    // Uruchom w tle bez czekania
    _predictivePreloadInBackground();
  }

  void _predictivePreloadInBackground() async {
    try {
      final futures = <Future>[];

      final favorites = CacheManager.get<List>('favorites_pets');
      if (favorites != null && favorites.isNotEmpty) {
        dev.log('Preloading favorite pet details...');
        // Preload pierwszych 3 ulubionych
        for (int i = 0; i < 3 && i < favorites.length; i++) {
          futures.add(
              PetService().getPetById(favorites[i].id).catchError((_) {})
          );
        }
      }

      futures.add(
          PetService().getPetsWithDefaultFilters().catchError((_) {})
      );

      futures.add(
          ReservationService().getAvailableSlots().catchError((_) {})
      );
      futures.add(
          ReservationService().getMyReservations().catchError((_) {})
      );

      futures.add(
          MessageService().getConversations().catchError((_) {})
      );

      await Future.wait(futures).timeout(Duration(seconds: 8));

      dev.log('✅ Predictive preloading completed');
    } catch (e) {
      dev.log('Predictive preloading failed: $e');
    }
  }

  /// Reset preloader state
  void reset() {
    _isPreloadingComplete = false;
    _isPreloadingInProgress = false;
    _loadingSteps.clear();
  }

  /// Cleanup
  void dispose() {
    _progressController.close();
  }

  /// Zwraca szczegóły ładowania dla debugowania
  List<String> get loadingSteps => List.unmodifiable(_loadingSteps);
}

/// Model progress preloadingu
class PreloadProgress {
  final int currentStep;
  final int totalSteps;
  final String stepName;
  final bool isComplete;

  PreloadProgress({
    required this.currentStep,
    required this.totalSteps,
    required this.stepName,
    required this.isComplete,
  });

  double get progress => totalSteps > 0 ? currentStep / totalSteps : 0.0;

  @override
  String toString() => 'PreloadProgress($currentStep/$totalSteps: $stepName)';
}

/// Model kroku preloadingu
class PreloadStep {
  final String name;
  final Future<void> Function() action;

  PreloadStep(this.name, this.action);
}