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
import '../models/filter_preferences.dart';
import '../views/community_support_view.dart';
import '../views/favorites_view.dart';
import '../views/messages_view.dart';
import '../views/profile_view.dart';
import '../widgets/profile/notifications_sheet.dart';
import 'discovery_settings_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initAnimations();
    _loadFiltersAndPets();
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

  /// Ładuje filtry użytkownika i na ich podstawie pobiera zwierzęta
  Future<void> _loadFiltersAndPets() async {
    try {
      _currentFilters = await FilterPreferencesService().getFilterPreferences();
      await _loadPets();
    } catch (e) {
      print('Błąd podczas ładowania filtrów: $e');
      // Jeśli błąd z filtrami, użyj domyślnych
      _currentFilters = FilterPreferences();
      await _loadPets();
    }
  }

  /// Pobiera zwierzęta na podstawie aktualnych filtrów
  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final petService = PetService();
      List<Pet> petsData;

      if (_currentFilters != null) {
        // Użyj filtrów użytkownika
        petsData = await petService.getPetsWithCustomFilters(_currentFilters!);
      } else {
        // Fallback - użyj domyślnych filtrów
        petsData = await petService.getPetsWithDefaultFilters();
      }

      if (mounted) {
        setState(() {
          _pets.clear();
          _pets.addAll(petsData);
          _isLoading = false;
          _currentIndex = 0; // Reset do pierwszego zwierzaka

          // Generujemy klucze dla każdego zwierzaka
          _cardKeys.clear();
          for (int i = 0; i < _pets.length; i++) {
            _cardKeys.add(GlobalKey<State<StatefulWidget>>());
          }
        });
      }
    } catch (e) {
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

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationsSheet(),
    );
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
        _likePet(_pets[_currentIndex]);
      }

      setState(() {
        if (_currentIndex < _pets.length - 1) {
          _currentIndex++;
        } else {
          // Jeśli koniec listy, przeładuj zwierzęta
          _loadPets();
        }
      });

      _completeSwipeReset();
    });
  }

  void _likePet(Pet pet) async {
    try {
      final petService = PetService();
      final response = await petService.likePet(pet.id);

      if (mounted && response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dodano ${pet.name} do polubionych!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        throw Exception('Nie udało się polubić zwierzaka');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się polubić: $e')),
        );
      }
    }
  }

  void _onActionButtonPressed(SwipeDirection direction) {
    if (_isLoading || _pets.isEmpty || _isAnimating) return;
    _finishSwipe(direction);
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
      setState(() {
        _currentFilters = result;
      });
      await _loadPets();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: _showDiscoverySettings,
            tooltip: 'Ustawienia odkrywania',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HomeView(),
                ),
              );
            },
            tooltip: 'Ustawienia aplikacji',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: _showNotifications,
            tooltip: 'Powiadomienia',
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
              onPressed: _loadPets,
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
              onPressed: _showDiscoverySettings,
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
                // Prebuffer karty w tle
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

                // Karta zwierzęcia w tle (następna karta)
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

                // Aktualna karta zwierzęcia
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

                // Indykatory swipe'a
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

        // Przyciski akcji
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