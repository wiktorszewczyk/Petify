import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../widgets/cards/pet_mini_card.dart';
import '../styles/colors.dart';
import '../services/pet_service.dart';
import '../services/cache/cache_manager.dart';
import '../views/pet_details_view.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({Key? key}) : super(key: key);

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> with AutomaticKeepAliveClientMixin {
  late final PetService _petService;
  List<Pet>? _favoritePets;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _petService = PetService();
    _loadFavoritesFromCache();
  }

  Future<void> _loadFavoritesFromCache() async {
    final cachedFavorites = CacheManager.get<List<Pet>>('favorites_pets');

    if (cachedFavorites != null && cachedFavorites.isNotEmpty) {
      setState(() {
        _favoritePets = cachedFavorites;
        _isLoading = false;
        _errorMessage = null;
      });

      print('🚀 FavoritesView: Załadowano ${cachedFavorites.length} ulubionych z cache!');

      _refreshFavoritesInBackground();
      return;
    }

    print('⚠️ FavoritesView: Brak cache, ładowanie standardowe...');
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pets = await _petService.getFavoritePets();
      setState(() {
        _favoritePets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nie udało się załadować ulubionych zwierząt. Spróbuj ponownie.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFavoritesInBackground() async {
    try {
      final newFavorites = await _petService.getFavoritePets();

      if (_favoritePets == null ||
          newFavorites.length != _favoritePets!.length ||
          _favoritesChanged(newFavorites)) {
        setState(() {
          _favoritePets = newFavorites;
        });
        print('🔄 FavoritesView: Zaktualizowano dane w tle');
      }
    } catch (e) {
      print('Background refresh failed: $e');
    }
  }

  bool _favoritesChanged(List<Pet> newFavorites) {
    if (_favoritePets == null) return true;
    if (newFavorites.length != _favoritePets!.length) return true;

    for (int i = 0; i < newFavorites.length; i++) {
      if (newFavorites[i].id != _favoritePets![i].id) return true;
    }
    return false;
  }

  Future<void> _removeFavorite(Pet pet) async {
    try {
      final response = await _petService.unlikePet(pet.id);

      if (response.statusCode == 200) {
        setState(() {
          _favoritePets!.removeWhere((element) => element.id == pet.id);
        });

        CacheManager.invalidatePattern('favorites_pets');
        print('🗑️ FavoritesView: Invalidated favorites cache after removing pet ${pet.id}');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pet.name} został usunięty z ulubionych'),
            action: SnackBarAction(
              label: 'Cofnij',
              onPressed: () async {
                final likeResponse = await _petService.likePet(pet.id);
                if (likeResponse.statusCode == 200) {
                  setState(() {
                    _favoritePets!.add(pet);
                  });
                  CacheManager.invalidatePattern('favorites_pets');
                  print('🗑️ FavoritesView: Invalidated favorites cache after re-adding pet ${pet.id}');
                }
              },
            ),
          ),
        );
      } else {
        throw Exception('Błąd serwera: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się usunąć zwierzaka z ulubionych: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Twoje ulubione',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
              ))
                  : _errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadFavorites,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Spróbuj ponownie'),
                    ),
                  ],
                ),
              )
                  : _favoritePets!.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _loadFavorites,
                color: AppColors.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _favoritePets!.length,
                    itemBuilder: (context, index) {
                      final pet = _favoritePets![index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PetDetailsView(pet: pet),
                            ),
                          );
                        },
                        onLongPress: () {
                          _showRemoveDialog(pet);
                        },
                        child: PetMiniCard(
                          pet: pet,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PetDetailsView(pet: pet),
                              ),
                            );
                          },
                          onRemove: () => _removeFavorite(pet),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Usuń z ulubionych'),
        content: Text('Czy na pewno chcesz usunąć ${pet.name} z ulubionych?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFavorite(pet);
            },
            child: Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Brak ulubionych zwierząt',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Przesuwaj w prawo, aby dodać zwierzaki do ulubionych.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.pets_rounded),
            label: const Text('Przeglądaj zwierzaki'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}