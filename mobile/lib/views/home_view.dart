import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/colors.dart';
import '../../models/pet_model.dart';
import '../../widgets/buttons/action_button.dart';
import '../../widgets/cards/pet_card.dart';
import '../../services/pet_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.pets, color: AppColors.primaryColor, size: 32)
            ),
            const SizedBox(width: 8),
            Text(
              'Petify',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
            onPressed: () {
              /// TODO: Przejście do ekranu ulubionych zwierząt
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
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
              'Ups! Coś poszło nie tak',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPets,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.2, curve: Curves.easeOutCubic),
      );
    }

    if (_pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 60, color: AppColors.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Brak zwierząt do wyświetlenia',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sprawdź ponownie później',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.2, curve: Curves.easeOutCubic),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (_currentIndex < _pets.length - 1)
                  Positioned(
                    child: Transform.scale(
                      scale: 0.9,
                      child: Opacity(
                        opacity: 0.7,
                        child: PetCard(pet: _pets[_currentIndex + 1]),
                      ),
                    ),
                  ),

                if (_pets.isNotEmpty && _currentIndex < _pets.length)
                  GestureDetector(
                    onPanUpdate: _onDragUpdate,
                    onPanEnd: _onDragEnd,
                    child: AnimatedBuilder(
                      animation: _swipeController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: _isDragging ? _dragPosition : _swipeAnimation.value,
                          child: Transform.rotate(
                            angle: _isDragging ? _dragPosition.dx * 0.001 : _rotationAnimation.value,
                            child: Stack(
                              children: [
                                child!,
                                // Wskaźnik kierunku
                                if (_swipeDirection != null)
                                  Positioned(
                                    top: 20,
                                    right: _swipeDirection == SwipeDirection.right ? 20 : null,
                                    left: _swipeDirection == SwipeDirection.left ? 20 : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _swipeDirection == SwipeDirection.right
                                            ? Colors.green.withOpacity(0.8)
                                            : Colors.red.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _swipeDirection == SwipeDirection.right ? 'LUBIĘ TO!' : 'POMIŃ',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: PetCard(pet: _pets[_currentIndex]),
                    ),
                  ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionButton(
                icon: Icons.close,
                backgroundColor: Colors.red,
                onPressed: () => _onActionButtonPressed(SwipeDirection.left),
              ).animate().scale(delay: 100.ms),

              ActionButton(
                icon: Icons.favorite,
                backgroundColor: Colors.green,
                onPressed: () => _onActionButtonPressed(SwipeDirection.right),
                size: 70,
              ).animate().scale(delay: 200.ms),

              ActionButton(
                icon: Icons.star,
                backgroundColor: AppColors.primaryColor,
                onPressed: () {
                  /// TODO: Logika superpolubienia do implementacji
                },
              ).animate().scale(delay: 300.ms),
            ],
          ),
        ),
      ],
    );
  }
}

enum SwipeDirection { left, right }