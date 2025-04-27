import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/support_options_sheet.dart';
import '../../styles/colors.dart';
import '../../models/pet_model.dart';
import '../../widgets/buttons/action_button.dart';
import '../../widgets/cards/pet_card.dart';
import '../../services/pet_service.dart';
import '../views/categories_view.dart';
import '../views/favorites_view.dart';
import '../views/messages_view.dart';
import '../views/profile_view.dart';
import 'app_settings_view.dart';
import 'discovery_settings_sheet.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  final List<PetModel> _pets = [];
  bool _isLoading = true;
  bool _isError = false;
  int _currentIndex = 0;
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _rotationAnimation;

  Offset _dragPosition = Offset.zero;
  SwipeDirection? _swipeDirection;

  // Current tab index for bottom navigation
  int _selectedTabIndex = 0;

  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

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

    _loadPets();
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final petService = PetService();
      final petsData = await petService.getPets();

      if (mounted) {
        setState(() {
          _pets.clear();
          _pets.addAll(petsData);
          _isLoading = false;
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

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isLoading || _pets.isEmpty) return;

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
    if (_isLoading || _pets.isEmpty) return;

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

  void _finishSwipe(SwipeDirection direction) {
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
          _loadPets();
        }

        _dragPosition = Offset.zero;
        _swipeDirection = null;
        _swipeController.reset();
      });
    });
  }

  void _likePet(PetModel pet) async {
    try {
      final petService = PetService();
      await petService.likePet(pet.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dodano ${pet.name} do polubionych!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
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
    if (_isLoading || _pets.isEmpty) return;
    _finishSwipe(direction);
  }

  void _showSupportOptions() {
    if (_isLoading || _pets.isEmpty) return;

    final currentPet = _pets[_currentIndex];

    // showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   backgroundColor: Colors.transparent,
    //   builder: (context) => SupportOptionsSheet(pet: currentPet),
    // );
  }

  void _showDiscoverySettings() async {
    final result = await DiscoverySettingsSheet.show<Map<String, dynamic>>(context);

    if (!mounted) return;

    if (result == 'reset') {
      // przywróć domyślne filtry
    } else if (result != null) {
      // zastosuj filtry z result
      _loadPets(/* pass filters */);
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
            Icon(Icons.pets, color: AppColors.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Petify',
              style: GoogleFonts.poppins(
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
              // Implementacja przejścia do ustawień aplikacji
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HomeView(),
                  // const AppSettingsView(),
                ),
              );
            },
            tooltip: 'Ustawienia aplikacji',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    // Różne widoki w zależności od wybranej zakładki
    switch (_selectedTabIndex) {
      case 0:
        return _buildSwipeView();
      case 1:
        return _buildSwipeView();
        // return const CategoriesView();
      case 2:
        // return _buildSwipeView();
        return const FavoritesView();
      case 3:
        // return _buildSwipeView();
        return const MessagesView();
      case 4:
        return _buildSwipeView();
        // return const ProfileView();
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
              children: [
                // Karty zwierząt w tle (jeśli są kolejne)
                if (_currentIndex < _pets.length - 1)
                  Positioned.fill(
                    child: PetCard(
                      pet: _pets[_currentIndex + 1],
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
                          final offset = _isDragging ? _dragPosition : _swipeAnimation.value;
                          final angle = _isDragging
                              ? _dragPosition.dx * 0.001
                              : _rotationAnimation.value;

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
              _buildNavBarItem(1, Icons.category_outlined, Icons.category),
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