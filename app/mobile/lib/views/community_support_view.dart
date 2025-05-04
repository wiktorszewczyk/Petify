import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/colors.dart';
import '../../widgets/buttons/action_button.dart';
import '../../models/shelter_post.dart';

class CommunitySupportView extends StatefulWidget {
  const CommunitySupportView({super.key});

  @override
  State<CommunitySupportView> createState() => _CommunitySupportViewState();
}

class _CommunitySupportViewState extends State<CommunitySupportView> {
  bool _isLoading = false;
  List<ShelterPost> _shelterPosts = [];
  bool _isVolunteer = false;

  // Przykładowe zdjęcia dla schronisk - używamy zasobów zastępczych
  // do czasu implementacji backendu
  final List<String> _placeholderImages = [
    'https://images.pexels.com/photos/406014/pexels-photo-406014.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // pies
    'https://images.pexels.com/photos/2352276/pexels-photo-2352276.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // karma dla kotów
    'https://images.pexels.com/photos/1633522/pexels-photo-1633522.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // dzień otwarty
    'https://images.pexels.com/photos/1254140/pexels-photo-1254140.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // spacer z psem
  ];

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
    _loadShelterPosts();
  }

  Future<void> _loadUserStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isVolunteer = false;
    });
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
          description: 'Potrzebujemy karmy dla kotów, które niedawno do nas trafiły. Zbieramy suchą karmę oraz puszki.',
          imageUrl: _placeholderImages[1],
          date: DateTime.now().subtract(const Duration(days: 2)),
          location: 'Warszawa, ul. Zwierzyniecka 5',
        ),
        ShelterPost(
          id: '2',
          title: 'Dzień otwarty w schronisku',
          shelterName: 'Schronisko dla zwierząt "Azyl"',
          description: 'Zapraszamy wszystkich na dzień otwarty w naszym schronisku! Poznaj naszych podopiecznych i dowiedz się jak pomóc.',
          imageUrl: _placeholderImages[2],
          date: DateTime.now().subtract(const Duration(days: 1)),
          location: 'Kraków, ul. Adopcyjna 12',
        ),
        ShelterPost(
          id: '3',
          title: 'Szukamy koców i zabawek',
          shelterName: 'Fundacja "Łapa w Łapę"',
          description: 'Potrzebujemy koców, poduszek oraz zabawek dla psów i kotów. Pomóż nam zapewnić komfort naszym podopiecznym!',
          imageUrl: _placeholderImages[0],
          date: DateTime.now().subtract(const Duration(days: 4)),
          location: 'Wrocław, ul. Schroniskowa 23',
        ),
      ];

      setState(() {
        _shelterPosts = posts;
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

  void _navigateToShelterSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Przejście do ekranu wsparcia schronisk')),
    );
  }

  void _navigateToVolunteerWalk() {
    if (_isVolunteer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Przejście do ekranu spacerów jako wolontariusz')),
      );
    } else {
      _showVolunteerApplicationPrompt();
    }
  }

  void _navigateToShelterPosts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Przejście do ekranu ogłoszeń schronisk')),
    );
  }

  void _navigateToEvents() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Przejście do ekranu wydarzeń')),
    );
  }

  void _showVolunteerApplicationPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Zostań wolontariuszem',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Chcesz pomagać zwierzakom w schroniskach poprzez wspólne spacery? '
              'Złóż wniosek o zostanie wolontariuszem!',
          style: GoogleFonts.poppins(),
          textAlign: TextAlign.justify,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToVolunteerApplication();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: Text('Złóż wniosek'),
          ),
        ],
      ),
    );
  }

  void _navigateToVolunteerApplication() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Przejście do formularza aplikacji na wolontariusza')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadShelterPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Społeczność',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Odkryj jak możesz pomóc zwierzętom w potrzebie',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                _buildMainSupportCard(),
                const SizedBox(height: 24),
                _buildActionCardsRow(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Najnowsze ogłoszenia',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToShelterPosts,
                      child: Text(
                        'Zobacz wszystkie',
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPostsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainSupportCard() {
    return InkWell(
      onTap: _navigateToShelterSupport,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -15,
              child: Icon(
                Icons.pets,
                size: 120,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Pomóż schroniskom',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wesprzyj finansowo lub materialnie schroniska i pomóż zwierzętom znaleźć nowy dom',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Dowiedz się więcej',
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
      begin: 0.2,
      end: 0,
      duration: 300.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildActionCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'Wyprowadź psa',
            icon: Icons.directions_walk,
            color: Colors.blue,
            isLocked: !_isVolunteer,
            onTap: _navigateToVolunteerWalk,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            title: 'Wydarzenia',
            icon: Icons.event,
            color: Colors.orange,
            onTap: _navigateToEvents,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    bool isLocked = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            if (isLocked) ...[
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.lock_outline, color: Colors.white, size: 40),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Dowiedz się więcej',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
      begin: .2,
      end: 0,
      duration: 300.ms,
      delay: 100.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildPostsList() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (_shelterPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              Icon(Icons.announcement_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Brak aktualnych ogłoszeń',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _shelterPosts.length,
      itemBuilder: (context, index) {
        final post = _shelterPosts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(ShelterPost post) {
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
              child: Image.network(
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
                    const SizedBox(width: 8),
                    Text(
                      '${post.date.day}.${post.date.month}.${post.date.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                if (post.location != null) ...[
                  const SizedBox(height: 4),
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
                ],
                const SizedBox(height: 8),
                Text(
                  post.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  post.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
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
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Przejście do wsparcia schroniska')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Wesprzyj',
                        style: GoogleFonts.poppins(
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
      begin: 0.2,
      end: 0,
      duration: 300.ms,
      delay: 150.ms,
      curve: Curves.easeOutCubic,
    );
  }
}