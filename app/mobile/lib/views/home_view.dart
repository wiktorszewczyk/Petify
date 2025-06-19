import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/support_options_sheet.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../styles/colors.dart';
import '../../models/pet.dart';
import '../../widgets/buttons/action_button.dart';
import '../../widgets/cards/pet_card.dart';
import '../../services/pet_service.dart';
import '../../services/filter_preferences_service.dart';
import '../../services/notification_service.dart';
import '../../services/cache/cache_manager.dart';
import '../models/filter_preferences.dart';
import '../views/community_support_view.dart';
import '../views/favorites_view.dart';
import '../views/messages_view.dart';
import '../views/profile_view.dart';
import '../widgets/profile/notifications_sheet.dart';
import 'discovery_settings_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/preloader/behavior_tracker.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<Pet> _pets = [];
  bool _isLoading = true;
  bool _isError = false;
  int _currentIndex = 0;
  late CardSwiperController _cardController;
  FilterPreferences? _currentFilters;

  int _selectedTabIndex = 0;
  bool _isSwiping = false;

  final Set<int> _likedPetIds = {};
  final NotificationService _notificationService = NotificationService();
  final BehaviorTracker _behaviorTracker = BehaviorTracker();
  int _unreadNotificationCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cardController = CardSwiperController();
    _loadCachedDataFirst();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationService.notificationStream.listen((notifications) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = _notificationService.getUnreadCount();
        });
      }
    });

    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    setState(() {
      _unreadNotificationCount = _notificationService.getUnreadCount();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedDataFirst() async {
    await _loadLikedPetsFromBackend();

    final cachedFilters = CacheManager.get<FilterPreferences>('filter_preferences');

    if (cachedFilters != null) {
      final cacheKey = _generatePetsCacheKey(cachedFilters);
      final cachedPets = CacheManager.get<List<Pet>>(cacheKey);

      if (cachedPets != null && cachedPets.isNotEmpty) {
        final filteredCachedPets = cachedPets.where((pet) => !_likedPetIds.contains(pet.id)).toList();

        setState(() {
          _currentFilters = cachedFilters;
          _pets.clear();
          _pets.addAll(filteredCachedPets);
          _isLoading = false;
          _isError = false;
          _currentIndex = 0;
        });

        print('🚀 HomeView: Załadowano ${_pets.length} zwierząt z cache (po filtrowaniu ${_likedPetIds.length} polubionych)');

        _refreshDataInBackground();

        return;
      }
    }

    print('⚠️ HomeView: Brak cache, ładowanie standardowe...');
    await _loadFiltersAndPets();
  }

  String _generatePetsCacheKey(FilterPreferences filterPrefs) {
    final params = {
      'vaccinated': filterPrefs.onlyVaccinated,
      'urgent': filterPrefs.onlyUrgent,
      'sterilized': filterPrefs.onlySterilized,
      'kidFriendly': filterPrefs.kidFriendly,
      'minAge': filterPrefs.minAge,
      'maxAge': filterPrefs.maxAge,
      'types': filterPrefs.animalTypes.join(','),
      'maxDistance': filterPrefs.maxDistance,
      'useCurrentLocation': filterPrefs.useCurrentLocation,
      'selectedCity': filterPrefs.selectedCity,
    };

    final sortedKeys = params.keys.toList()..sort();
    final keyParts = sortedKeys.map((key) => '$key:${params[key]}').join(',');
    return 'pets_default:$keyParts';
  }

  Future<void> _loadFiltersAndPets() async {
    try {
      _currentFilters = await FilterPreferencesService().getFilterPreferences();
      await _loadPets();
    } catch (e) {
      print('Błąd podczas ładowania filtrów: $e');
      _currentFilters = FilterPreferences();
      await _loadPets();
    }
  }

  Future<void> _refreshDataInBackground() async {
    try {
      final petService = PetService();

      await Future.delayed(Duration(milliseconds: 200));

      final newPets = await petService.getPetsWithDefaultFilters();

      final filteredNewPets = newPets.where((pet) => !_likedPetIds.contains(pet.id)).toList();

      if (mounted && filteredNewPets.isNotEmpty) {
        final remainingPets = _pets.length - _currentIndex;
        if (remainingPets <= 3) {
          setState(() {
            final currentPetIds = _pets.map((p) => p.id).toSet();
            final newUniquePets = filteredNewPets.where((p) => !currentPetIds.contains(p.id)).toList();

            if (newUniquePets.isNotEmpty) {
              final finalUniquePets = newUniquePets.where((p) => !_likedPetIds.contains(p.id)).toList();

              if (finalUniquePets.isNotEmpty) {
                _pets.addAll(finalUniquePets);
                print('🔄 HomeView: Dodano ${finalUniquePets.length} nowych zwierząt (po podwójnym filtrowaniu)');
              }
            }
          });
        }
      }
    } catch (e) {
      print('Background refresh failed: $e');
    }
  }

  bool _petsChanged(List<Pet> newPets) {
    if (newPets.length != _pets.length) return true;

    for (int i = 0; i < newPets.length; i++) {
      if (newPets[i].id != _pets[i].id) return true;
    }
    return false;
  }

  Future<void> _loadLikedPetsFromBackend() async {
    try {
      final petService = PetService();
      final likedPets = await petService.getFavoritePets();

      _likedPetIds.clear();
      _likedPetIds.addAll(likedPets.map((pet) => pet.id));

      print('💖 HomeView: Załadowano ${_likedPetIds.length} polubionych zwierząt z backendu');
    } catch (e) {
      print('❌ HomeView: Błąd ładowania polubionych zwierząt: $e');
    }
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final petService = PetService();
      List<Pet> petsData;

      if (_currentFilters != null) {
        petsData = await petService.getPetsWithCustomFilters(_currentFilters!);
        print('🐶 HomeView: Ładowanie zwierząt z custom filters: ${petsData.length} znalezionych');
      } else {
        petsData = await petService.getPetsWithDefaultFilters();
        print('🐶 HomeView: Ładowanie zwierząt z default filters: ${petsData.length} znalezionych');
      }

      final filteredPets = petsData.where((pet) => !_likedPetIds.contains(pet.id)).toList();
      print('🔍 HomeView: Po filtrowaniu polubionych: ${filteredPets.length} z ${petsData.length} (polubione: ${_likedPetIds.length})');

      if (mounted) {
        setState(() {
          _pets.clear();
          _pets.addAll(filteredPets);
          _isLoading = false;
          _currentIndex = 0;
        });

        print('✅ HomeView: Załadowano ${_pets.length} zwierząt, currentIndex: $_currentIndex');
      }
    } catch (e) {
      print('❌ HomeView: Błąd ładowania zwierząt: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się pobrać danych: $e')),
        );
      }
    }
  }


  bool _onCardSwiped(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (!mounted || _isSwiping) return false;

    setState(() {
      _isSwiping = true;
      _currentIndex = currentIndex ?? 0;
    });

    final swipedPet = _pets[previousIndex];

    if (direction == CardSwiperDirection.right) {
      _likePet(swipedPet);
    } else {
      print('❌ HomeView: Pominął pet ${swipedPet.id}');
    }

    if (_pets.length - _currentIndex <= 2) {
      _loadMorePets();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isSwiping = false;
        });
      }
    });

    return true;
  }

  void _likePet(Pet pet) {
    _likedPetIds.add(pet.id);
    print('💖 HomeView: Dodano pet ${pet.id} do lokalnej listy polubionych');
    _likePetInBackground(pet);
  }

  void _loadMorePets() async {
    try {
      print('🔍 HomeView: Ładowanie więcej zwierząt...');
      final petService = PetService();
      final newPets = await petService.getPetsWithDefaultFilters();
      final availablePets = newPets.where((pet) =>
      !_likedPetIds.contains(pet.id) &&
          !_pets.any((existingPet) => existingPet.id == pet.id)
      ).toList();

      if (availablePets.isNotEmpty) {
        setState(() {
          _pets.addAll(availablePets);
        });
        print('✨ HomeView: Dodano ${availablePets.length} nowych zwierząt');
      }
    } catch (e) {
      print('❌ HomeView: Błąd podczas ładowania nowych zwierząt: $e');
    }
  }


  void _likePetInBackground(Pet pet) async {
    try {
      final petService = PetService();
      final response = await petService.likePet(pet.id);

      if (mounted && response.statusCode == 200) {
        _behaviorTracker.trackPetLike(pet.id);

        CacheManager.invalidatePattern('favorites_pets');
        print('🗑️ HomeView: Invalidated favorites cache after liking pet ${pet.id}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dodano ${pet.name} do polubionych!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        _likedPetIds.remove(pet.id);
        throw Exception('Nie udało się polubić zwierzaka');
      }
    } catch (e) {
      _likedPetIds.remove(pet.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się polubić: $e')),
        );
      }
    }
  }

  void _onActionButtonPressed(CardSwiperDirection direction) {
    if (_isLoading || _pets.isEmpty || _isSwiping || _currentIndex >= _pets.length) return;

    _cardController.swipe(direction);
  }

  void _showSupportOptions() {
    if (_isLoading || _pets.isEmpty || _currentIndex >= _pets.length) return;

    final currentPet = _pets[_currentIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SupportOptionsSheet(pet: currentPet),
    );
  }

  void _showDiscoverySettings() async {
    final result = await DiscoverySettingsSheet.show<FilterPreferences>(
      context,
      currentPreferences: _currentFilters,
    );

    if (!mounted) return;

    if (result != null) {
      print('🔧 Discovery settings changed, invalidating cache and reloading pets');

      CacheManager.invalidatePattern('pets_');
      CacheManager.invalidatePattern('filter_preferences');

      _likedPetIds.clear();
      print('🗑️ HomeView: Wyczyszczono lokalną listę polubionych przy zmianie filtrów');

      setState(() {
        _currentFilters = result;
        _isLoading = true;
        _pets.clear();
        _currentIndex = 0;
      });

      await _loadPets();
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsSheet(),
    ).then((_) {
      _updateUnreadCount();
    });
  }

  Future<void> _refreshAllData() async {
    try {
      CacheManager.invalidatePattern('pets_');
      CacheManager.invalidatePattern('favorites_pets');

      print('🔄 HomeView: Odświeżanie wszystkich danych...');

      await _loadLikedPetsFromBackend();
      await _loadFiltersAndPets();

      print('✅ HomeView: Odświeżanie zakończone pomyślnie');
    } catch (e) {
      print('❌ HomeView: Błąd podczas odświeżania: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się odświeżyć danych: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/logo.svg',
              width: 42,
              height: 42,
            ),
            const SizedBox(width: 8),
            Text(
              'Petify',
              style: GoogleFonts.pacifico(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedTabIndex == 0)
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.black),
              onPressed: _showDiscoverySettings,
              tooltip: 'Ustawienia odkrywania',
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                onPressed: _showNotifications,
                tooltip: 'Powiadomienia',
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildSwipeView();
      case 1:
        return const CommunitySupportView();
      case 2:
        return const FavoritesView();
      case 3:
        return const MessagesView();
      case 4:
        return const ProfileView();
      default:
        return _buildSwipeView();
    }
  }

  Widget _buildSwipeView() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Wczytywanie zwierzaków...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_isError) {
      return RefreshIndicator(
        onRefresh: _refreshAllData,
        color: AppColors.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Nie udało się załadować danych',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pociągnij w dół, aby odświeżyć',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshAllData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Spróbuj ponownie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_pets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshAllData,
        color: AppColors.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/empty_pets.png',
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Brak zwierząt w okolicy',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Spróbuj zwiększyć zasięg poszukiwań\nlub zmienić filtry',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pociągnij w dół, aby odświeżyć',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _loadLikedPetsFromBackend();
                      _showDiscoverySettings();
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Zmień filtry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAllData,
      color: AppColors.primaryColor,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: CardSwiper(
                controller: _cardController,
                cardsCount: _pets.length,
                initialIndex: _currentIndex,
                onSwipe: _onCardSwiped,
                allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
                threshold: 50,
                maxAngle: 15,
                scale: 0.95,
                backCardOffset: const Offset(0, -8),
                cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
                  if (index >= _pets.length) return const SizedBox.shrink();

                  return Stack(
                    children: [
                      PetCard(
                        pet: _pets[index],
                        key: ValueKey('pet_${_pets[index].id}'),
                      ),

                      if (horizontalOffsetPercentage > 0.1)
                        Positioned(
                          top: 40,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite, color: Colors.white, size: 24),
                                const SizedBox(width: 6),
                                Text(
                                  'POLUB',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scale(
                            duration: 200.ms,
                            curve: Curves.elasticOut,
                          ),
                        ),

                      if (horizontalOffsetPercentage < -0.1)
                        Positioned(
                          top: 40,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.close, color: Colors.white, size: 24),
                                const SizedBox(width: 6),
                                Text(
                                  'POMIŃ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scale(
                            duration: 200.ms,
                            curve: Curves.elasticOut,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ActionButton(
                  icon: Icons.close,
                  backgroundColor: Colors.red,
                  size: 60,
                  onPressed: () => _onActionButtonPressed(CardSwiperDirection.left),
                ),
                ActionButton(
                  icon: Icons.favorite,
                  backgroundColor: Colors.green,
                  size: 75,
                  onPressed: () => _onActionButtonPressed(CardSwiperDirection.right),
                ),
                ActionButton(
                  icon: Icons.volunteer_activism,
                  backgroundColor: Colors.blue,
                  size: 60,
                  onPressed: _showSupportOptions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(0, Icons.home_outlined, Icons.home),
              _buildNavBarItem(1, Icons.diversity_1_outlined, Icons.diversity_1),
              _buildNavBarItem(2, Icons.favorite_outline, Icons.favorite),
              _buildNavBarItem(3, Icons.message_outlined, Icons.message),
              _buildNavBarItem(4, Icons.person_outline, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, IconData activeIcon) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });

        final screenNames = ['home', 'community', 'favorites', 'messages', 'profile'];
        if (index < screenNames.length) {
          _behaviorTracker.trackScreenVisit(screenNames[index]);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        )
            : null,
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primaryColor : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}

