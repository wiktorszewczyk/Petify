import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/shelter_support_view.dart';
import 'package:mobile/views/volunteer_application_view.dart';
import 'package:mobile/views/volunteer_walks_view.dart';
import 'package:mobile/views/my_applications_view.dart';
import 'package:mobile/views/announcements_view.dart';
import '../../styles/colors.dart';
import '../../models/shelter_post.dart';
import '../../services/user_service.dart';
import 'events_view.dart';

class CommunitySupportView extends StatefulWidget {
  const CommunitySupportView({super.key});

  @override
  State<CommunitySupportView> createState() => _CommunitySupportViewState();
}

class _CommunitySupportViewState extends State<CommunitySupportView> {
  bool _isVolunteer = false;
  String? _volunteerStatus;

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    try {
      final user = await UserService().getCurrentUser();
      setState(() {
        _volunteerStatus = user.volunteerStatus;
        _isVolunteer = user.volunteerStatus == 'ACTIVE';
      });
    } catch (e) {
      setState(() {
        _volunteerStatus = null;
        _isVolunteer = false;
      });
    }
  }

  void _navigateToShelterSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShelterSupportView()),
    );
  }

  void _navigateToVolunteerWalk() {
    if (_isVolunteer) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VolunteerWalksView()),
      );
    } else {
      _showVolunteerApplicationPrompt();
    }
  }

  void _navigateToMyApplications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyApplicationsView()),
    );
  }

  void _navigateToAnnouncements() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnnouncementsView()),
    );
  }

  void _navigateToEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventsView()),
    );
  }

  void _showVolunteerApplicationPrompt() {
    String message = 'Chcesz pomagać zwierzakom w schroniskach poprzez wspólne spacery? Złóż wniosek o zostanie wolontariuszem!';
    String buttonText = 'Złóż wniosek';

    if (_volunteerStatus == 'PENDING') {
      message = 'Twój wniosek o zostanie wolontariuszem jest w trakcie rozpatrywania. Poczekaj na decyzję administracji.';
      buttonText = 'OK';
    } else if (_volunteerStatus == 'INACTIVE') {
      message = 'Twoje konto wolontariusza jest nieaktywne. Skontaktuj się z administracją aby je reaktywować.';
      buttonText = 'OK';
    }

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
          message,
          style: GoogleFonts.poppins(),
          textAlign: TextAlign.justify,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          if (_volunteerStatus == null || _volunteerStatus == 'NONE')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToVolunteerApplication();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.black,
              ),
              child: Text(buttonText),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.black,
              ),
              child: Text(buttonText),
            ),
        ],
      ),
    );
  }

  void _navigateToVolunteerApplication() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const VolunteerApplicationView()
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserStatus();
        },
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
                _buildNewActionGrid(),
                const SizedBox(height: 24),
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

  Widget _buildNewActionGrid() {
    return Column(
      children: [
        Row(
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
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Moje wnioski',
                icon: Icons.description,
                color: Colors.green,
                onTap: _navigateToMyApplications,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Ogłoszenia',
                icon: Icons.announcement,
                color: Colors.purple,
                onTap: _navigateToAnnouncements,
              ),
            ),
          ],
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
                      'Tylko dla wolontariuszy',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
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
}