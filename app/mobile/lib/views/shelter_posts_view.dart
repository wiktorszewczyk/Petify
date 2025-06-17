import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shelter_post.dart';
import '../styles/colors.dart';

class ShelterPostsView extends StatefulWidget {
  const ShelterPostsView({super.key});

  @override
  State<ShelterPostsView> createState() => _ShelterPostsViewState();
}

class _ShelterPostsViewState extends State<ShelterPostsView> {
  bool _isLoading = false;
  List<ShelterPost> _shelterPosts = [];
  String _selectedFilter = 'Wszystkie';
  final List<String> _filters = ['Wszystkie', 'Zbiórki', 'Wydarzenia', 'Adopcje'];

  final TextEditingController _searchController = TextEditingController();
  List<ShelterPost> _filteredPosts = [];

  final List<String> _placeholderImages = [
    'https://images.pexels.com/photos/406014/pexels-photo-406014.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    'https://images.pexels.com/photos/2352276/pexels-photo-2352276.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    'https://images.pexels.com/photos/1633522/pexels-photo-1633522.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    'https://images.pexels.com/photos/1254140/pexels-photo-1254140.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    'https://images.pexels.com/photos/551628/pexels-photo-551628.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    'https://images.pexels.com/photos/1906153/pexels-photo-1906153.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
  ];

  @override
  void initState() {
    super.initState();
    _loadShelterPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShelterPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      final posts = [
        ShelterPost(
          id: '1',
          title: 'Zbiórka karmy dla kotów',
          shelterName: 'Schronisko "Psia Łapka"',
          description: 'Potrzebujemy karmy dla kotów, które niedawno do nas trafiły. Zbieramy suchą karmę oraz puszki. Każda pomoc jest dla nas nieoceniona!',
          imageUrl: _placeholderImages[1],
          date: DateTime.now().subtract(const Duration(days: 2)),
          location: 'Warszawa, ul. Zwierzyniecka 5',
          supportOptions: {
            'types': ['Zbiórki'],
          },
        ),
        ShelterPost(
          id: '2',
          title: 'Dzień otwarty w schronisku',
          shelterName: 'Schronisko dla zwierząt "Azyl"',
          description: 'Zapraszamy wszystkich na dzień otwarty w naszym schronisku! Poznaj naszych podopiecznych i dowiedz się jak pomóc. W programie: zwiedzanie schroniska, prezentacja podopiecznych, konsultacje z behawiorystą oraz poczęstunek.',
          imageUrl: _placeholderImages[2],
          date: DateTime.now().subtract(const Duration(days: 1)),
          location: 'Kraków, ul. Adopcyjna 12',
          supportOptions: {
            'types': ['Wydarzenia'],
          },
        ),
        ShelterPost(
          id: '3',
          title: 'Szukamy koców i zabawek',
          shelterName: 'Fundacja "Łapa w Łapę"',
          description: 'Potrzebujemy koców, poduszek oraz zabawek dla psów i kotów. Pomóż nam zapewnić komfort naszym podopiecznym! Szczególnie potrzebne są: koce polarowe, maty ortopedyczne i zabawki interaktywne.',
          imageUrl: _placeholderImages[0],
          date: DateTime.now().subtract(const Duration(days: 4)),
          location: 'Wrocław, ul. Schroniskowa 23',
          supportOptions: {
            'types': ['Zbiórki'],
          },
        ),
        ShelterPost(
          id: '4',
          title: 'Zostań domem tymczasowym',
          shelterName: 'Kocia Przystań',
          description: 'Poszukujemy domów tymczasowych dla kotów po przejściach. Zapewniamy wsparcie medyczne, karmę oraz stały kontakt z behawiorystą. Jeśli masz miejsce i serce dla potrzebującego zwierzaka, odezwij się do nas!',
          imageUrl: _placeholderImages[4],
          date: DateTime.now().subtract(const Duration(days: 5)),
          location: 'Gdańsk, ul. Kocia 17',
          supportOptions: {
            'types': ['Adopcje'],
          },
        ),
        ShelterPost(
          id: '5',
          title: 'Warsztaty dla wolontariuszy',
          shelterName: 'Fundacja "Cztery Łapy"',
          description: 'Organizujemy szkolenie dla osób chcących zostać wolontariuszami w naszym schronisku. W programie: podstawy opieki nad zwierzętami, pierwsza pomoc, techniki pracy z psami lękliwymi. Zapisz się już dziś!',
          imageUrl: _placeholderImages[5],
          date: DateTime.now().subtract(const Duration(days: 3)),
          location: 'Poznań, ul. Wolontariacka 8',
          supportOptions: {
            'types': ['Wydarzenia'],
          },
        ),
        ShelterPost(
          id: '6',
          title: 'Spacery z psami ze schroniska',
          shelterName: 'Miejskie Schronisko dla Zwierząt',
          description: 'Zapraszamy wszystkich miłośników psów na sobotnie spacery z naszymi podopiecznymi. To dla nich szansa na chwilę normalności i radości poza boksem. Spotykamy się w każdą sobotę o 10:00 przed schroniskiem.',
          imageUrl: _placeholderImages[3],
          date: DateTime.now().subtract(const Duration(days: 6)),
          location: 'Łódź, ul. Schroniskowa 45',
          supportOptions: {
            'types': ['Wydarzenia'],
          },
        ),
        ShelterPost(
          id: '7',
          title: 'Pilnie potrzebne leki dla zwierząt',
          shelterName: 'Schronisko "Reksio"',
          description: 'Pilnie potrzebujemy leków przeciwbólowych i przeciwzapalnych dla naszych podopiecznych. Każda pomoc się liczy! Lista potrzebnych leków dostępna na naszej stronie internetowej.',
          imageUrl: _placeholderImages[0],
          date: DateTime.now().subtract(const Duration(days: 1)),
          location: 'Katowice, ul. Opiekuńcza 23',
          supportOptions: {
            'types': ['Zbiórki'],
          },
        ),
      ];

      setState(() {
        _shelterPosts = posts;
        _filterPosts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się pobrać ogłoszeń: $e')),
        );
      }
    }
  }

  void _filterPosts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (_selectedFilter == 'Wszystkie') {
        _filteredPosts = _shelterPosts.where((post) {
          return post.title.toLowerCase().contains(query) ||
              post.shelterName.toLowerCase().contains(query) ||
              post.description.toLowerCase().contains(query) ||
              (post.location != null && post.location!.toLowerCase().contains(query));
        }).toList();
      } else {
        _filteredPosts = _shelterPosts.where((post) {
          final types = post.supportOptions?['types'] as List?;
          final matchesFilter = types != null && types.contains(_selectedFilter);
          return matchesFilter &&
              (post.title.toLowerCase().contains(query) ||
                  post.shelterName.toLowerCase().contains(query) ||
                  post.description.toLowerCase().contains(query) ||
                  (post.location != null && post.location!.toLowerCase().contains(query)));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ogłoszenia schronisk',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        onRefresh: _loadShelterPosts,
        color: AppColors.primaryColor,
        child: Column(
          children: [
            _buildSearchAndFilterBar(),
            Expanded(
              child: _isLoading ? _buildLoadingIndicator() : _buildPostsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Szukaj ogłoszeń...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _filterPosts();
                },
              )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              _filterPosts();
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(filter),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                        _filterPosts();
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: AppColors.primaryColor.withOpacity(0.7),
                    checkmarkColor: Colors.black,
                    labelStyle: GoogleFonts.poppins(
                      color: isSelected ? Colors.black : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
      ),
    );
  }

  Widget _buildPostsList() {
    if (_filteredPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Brak ogłoszeń spełniających kryteria',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Spróbuj zmienić filtry lub wyszukiwaną frazę',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        return _buildPostCard(post, index);
      },
    );
  }

  Widget _buildPostCard(ShelterPost post, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    post.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                      ),
                    ),
                  ),

                  if (post.supportOptions != null &&
                      post.supportOptions!['types'] != null &&
                      (post.supportOptions!['types'] as List).isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getCategoryColor((post.supportOptions!['types'] as List).first),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (post.supportOptions!['types'] as List).first,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.home_work_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        post.shelterName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        '${post.date.day}.${post.date.month.toString().padLeft(2, '0')}.${post.date.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                if (post.location != null)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post.location!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                Text(
                  post.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                Text(
                  post.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Przejście do szczegółów ogłoszenia')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Szczegóły',
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
      begin: 0.1,
      end: 0,
      duration: 300.ms,
      delay: Duration(milliseconds: 50 * index),
      curve: Curves.easeOutCubic,
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Zbiórki':
        return Colors.blue;
      case 'Wydarzenia':
        return Colors.orange;
      case 'Adopcje':
        return Colors.green;
      default:
        return AppColors.primaryColor;
    }
  }
}