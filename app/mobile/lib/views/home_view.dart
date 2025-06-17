import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/support_options_sheet.dart';
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
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _rotationAnimation;
  FilterPreferences? _currentFilters;

  Offset _dragPosition = Offset.zero;
  SwipeDirection? _swipeDirection;

  int _selectedTabIndex = 0;

  bool _isDragging = false;
  bool _isAnimating = false;

  final List<GlobalKey<State<StatefulWidget>>> _cardKeys = [];

  final NotificationService _notificationService = NotificationService();
  final BehaviorTracker _behaviorTracker = BehaviorTracker();
  int _unreadNotificationCount = 0;

  final Set<int> _likedPetIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initAnimations();
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

  void _initAnimations() {
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _swipeController.dispose();
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

          _cardKeys.clear();
          for (int i = 0; i < _pets.length; i++) {
            _cardKeys.add(GlobalKey<State<StatefulWidget>>());
          }
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
              _pets.addAll(newUniquePets);
              for (int i = 0; i < newUniquePets.length; i++) {
                _cardKeys.add(GlobalKey<State<StatefulWidget>>());
              }
              print('🔄 HomeView: Dodano ${newUniquePets.length} nowych zwierząt (po filtrowaniu polubionych)');
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

          _cardKeys.clear();
          for (int i = 0; i < _pets.length; i++) {
            _cardKeys.add(GlobalKey<State<StatefulWidget>>());
          }
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

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isLoading || _pets.isEmpty || _isAnimating) return;

    setState(() {
      _isDragging = true;
      _dragPosition += details.delta;

      if (_dragPosition.dx > 20) {
        _swipeDirection = SwipeDirection.right;
      } else if (_dragPosition.dx < -20) {
        _swipeDirection = SwipeDirection.left;
      } else {
        _swipeDirection = null;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isLoading || _pets.isEmpty || _isAnimating) return;

    final swipedRight = _dragPosition.dx > MediaQuery.of(context).size.width * 0.2;
    final swipedLeft = _dragPosition.dx < -MediaQuery.of(context).size.width * 0.2;

    if (swipedRight) {
      _finishSwipe(SwipeDirection.right);
    } else if (swipedLeft) {
      _finishSwipe(SwipeDirection.left);
    } else {
      _resetPosition();
    }

    setState(() {
      _isDragging = false;
    });
  }

  void _resetPosition() {
    setState(() {
      _dragPosition = Offset.zero;
      _swipeDirection = null;
    });
  }

  void _completeSwipeReset() {
    if (!mounted) return;

    setState(() {
      _dragPosition = Offset.zero;
      _swipeDirection = null;
      _swipeController.reset();
      _initAnimations();
      _isAnimating = false;
    });
  }

  void _finishSwipe(SwipeDirection direction) {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final endX = direction == SwipeDirection.right ? screenWidth * 1.5 : -screenWidth * 1.5;

    setState(() {
      _swipeAnimation = Tween<Offset>(
        begin: _dragPosition,
        end: Offset(endX, 0),
      ).animate(CurvedAnimation(
        parent: _swipeController,
        curve: Curves.easeOutCubic,
      ));

      _rotationAnimation = Tween<double>(
        begin: _dragPosition.dx * 0.001,
        end: direction == SwipeDirection.right ? 0.3 : -0.3,
      ).animate(CurvedAnimation(
        parent: _swipeController,
        curve: Curves.easeOutCubic,
      ));
    });

    _swipeController.forward().then((_) {
      if (!mounted) return;

      if (direction == SwipeDirection.right) {
        _likePetAndRemove(_pets[_currentIndex]);
      } else {
        _moveToNextPet();
      }

      _completeSwipeReset();
    });
  }

  void _likePetAndRemove(Pet pet) {
    _likedPetIds.add(pet.id);
    print('💖 HomeView: Dodano pet ${pet.id} do lokalnej listy polubionych');

    _moveToNextPetAfterDelay();

    _likePetInBackground(pet);
  }

  void _moveToNextPet() {
    setState(() {
      if (_currentIndex < _pets.length - 1) {
        _currentIndex++;
      } else {
        _loadPets();
      }
    });
  }

  void _moveToNextPetAfterDelay() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          if (_currentIndex < _pets.length - 1) {
            _currentIndex++;
          } else {
            _loadPets();
          }
        });
      }
    });
  }


  void _likePetInBackground(Pet pet) async {
    try {
      final petService = PetService();
      final response = await petService.likePet(pet.id);

      if (mounted && response.statusCode == 200) {
        _behaviorTracker.trackPetLike(pet.id);

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

  void _onActionButtonPressed(SwipeDirection direction) {
    if (_isLoading || _pets.isEmpty || _isAnimating) return;

    _animateButtonPress(direction);
  }

  void _animateButtonPress(SwipeDirection direction) {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _swipeDirection = direction;
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final endX = direction == SwipeDirection.right ? screenWidth * 1.2 : -screenWidth * 1.2;

    setState(() {
      _swipeAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(endX, 0),
      ).animate(CurvedAnimation(
        parent: _swipeController,
        curve: Curves.easeInCubic,
      ));

      _rotationAnimation = Tween<double>(
        begin: 0,
        end: direction == SwipeDirection.right ? 0.2 : -0.2,
      ).animate(CurvedAnimation(
        parent: _swipeController,
        curve: Curves.easeInCubic,
      ));
    });

    _swipeController.duration = const Duration(milliseconds: 200);

    _swipeController.forward().then((_) {
      if (!mounted) return;

      if (direction == SwipeDirection.right) {
        _likePetAndRemove(_pets[_currentIndex]);
      } else {
        _moveToNextPet();
      }

      _swipeController.duration = const Duration(milliseconds: 300);

      _completeSwipeReset();
    });
  }

  void _showSupportOptions() {
    if (_isLoading || _pets.isEmpty) return;

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
        _currentIndex = 0;
        _pets.clear();
        _cardKeys.clear();
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
      return Center(
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
            ElevatedButton.icon(
              onPressed: () async {
                await _loadLikedPetsFromBackend();
                await _loadPets();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    if (_pets.isEmpty) {
      return Center(
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
      );
    }

    final currentPet = _pets[_currentIndex];

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_currentIndex < _pets.length - 2)
                  Positioned.fill(
                    child: PetCard(
                      pet: _pets[_currentIndex + 2],
                      key: _cardKeys.length > _currentIndex + 2 ? _cardKeys[_currentIndex + 2] : null,
                    ).animate().scale(
                      begin: const Offset(0.90, 0.90),
                      end: const Offset(0.90, 0.90),
                    ),
                  ),

                if (_currentIndex < _pets.length - 1)
                  Positioned.fill(
                    child: PetCard(
                      pet: _pets[_currentIndex + 1],
                      key: _cardKeys.length > _currentIndex + 1 ? _cardKeys[_currentIndex + 1] : null,
                    ).animate().scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(0.95, 0.95),
                    ),
                  ),

                if (_currentIndex < _pets.length)
                  Positioned.fill(
                    child: GestureDetector(
                      onPanUpdate: _onDragUpdate,
                      onPanEnd: _onDragEnd,
                      child: AnimatedBuilder(
                        animation: _swipeController,
                        builder: (context, child) {
                          final offset = _isAnimating ? _swipeAnimation.value : _dragPosition;
                          final angle = _isAnimating ? _rotationAnimation.value : _dragPosition.dx * 0.001;

                          return Transform.translate(
                            offset: offset,
                            child: Transform.rotate(
                              angle: angle,
                              child: child,
                            ),
                          );
                        },
                        child: PetCard(
                          pet: currentPet,
                          key: _cardKeys.length > _currentIndex ? _cardKeys[_currentIndex] : null,
                        ),
                      ),
                    ),
                  ),

                if (_swipeDirection == SwipeDirection.right)
                  Positioned(
                    top: 40,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.white, size: 30),
                          const SizedBox(width: 8),
                          Text(
                            'POLUB',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(
                      duration: 200.ms,
                      curve: Curves.easeOut,
                    ),
                  ),

                if (_swipeDirection == SwipeDirection.left)
                  Positioned(
                    top: 40,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.close, color: Colors.white, size: 30),
                          const SizedBox(width: 8),
                          Text(
                            'POMIŃ',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(
                      duration: 200.ms,
                      curve: Curves.easeOut,
                    ),
                  ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionButton(
                icon: Icons.close,
                backgroundColor: Colors.red,
                onPressed: () => _onActionButtonPressed(SwipeDirection.left),
              ),
              ActionButton(
                icon: Icons.favorite,
                backgroundColor: Colors.green,
                size: 70,
                onPressed: () => _onActionButtonPressed(SwipeDirection.right),
              ),
              ActionButton(
                icon: Icons.volunteer_activism,
                backgroundColor: Colors.blue,
                onPressed: _showSupportOptions,
              ),
            ],
          ),
        ),
      ],
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

enum SwipeDirection {
  left,
  right,
}