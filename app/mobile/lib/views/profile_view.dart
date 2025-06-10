import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/views/edit_profile_view.dart';
import 'package:mobile/views/volunteer_application_view.dart';
import '../models/user.dart';
import '../models/achievement.dart';
import '../services/user_service.dart';
import '../services/achievement_service.dart';
import '../styles/colors.dart';

import '../widgets/profile/profile_header.dart';
import '../widgets/profile/achievement_progress.dart';
import '../widgets/profile/quick_stats.dart';
import '../widgets/profile/achievements.dart';
import '../widgets/profile/active_achievements.dart';
import '../widgets/profile/volunteer_status_card.dart';
import 'auth/welcome_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _user;
  List<Achievement> _recentAchievements = [];
  bool _isLoading = true;
  bool _isError = false;
  late final ScrollController _scrollCtrl = ScrollController();
  bool _showToTop = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollCtrl.addListener(() {
      final shouldShow = _scrollCtrl.offset > 300;
      if (shouldShow != _showToTop) {
        setState(() => _showToTop = shouldShow);
      }
    });
    _loadUserProfile();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final userData = await UserService().getCurrentUser();
      final allAchievements =
      await AchievementService().getUserAchievements();

      if (!mounted) return;
      setState(() {
        _user = userData;
        // tylko 3 ostatnie odblokowane
        _recentAchievements = allAchievements
            .where((a) => a.isUnlocked)
            .toList()
          ..sort((a, b) =>
              b.dateAchieved!.compareTo(a.dateAchieved!));
        _recentAchievements = _recentAchievements.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się załadować profilu: $e')),
      );
    }
  }

  void _handleVolunteerSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VolunteerApplicationView(),
      ),
    ).then((_) {
      // Odśwież profil po powrocie z formularza aplikacji
      _loadUserProfile();
    });
  }

  Future<void> _onLogout() async {
    await UserService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeView()),
          (route) => false,
    );
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileView(user: _user!),
      ),
    );

    // Jeśli profil został zaktualizowany, odśwież dane
    if (result == true) {
      _loadUserProfile();
    }
  }

  bool _isVolunteer() {
    return _user?.volunteerStatus == 'ACTIVE';
  }

  bool _shouldShowVolunteerApplicationButton() {
    return _user?.volunteerStatus == null || _user?.volunteerStatus == 'NONE';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AnimatedScale(
        scale: _showToTop ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          heroTag: 'toTop',
          backgroundColor: AppColors.primaryColor,
          onPressed: () => _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          ),
          child: const Icon(Icons.keyboard_arrow_up),
        ),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingView()
          : _isError
          ? _buildErrorView()
          : _buildProfileContent(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Wczytywanie profilu...',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 60),
          const SizedBox(height: 16),
          const Text(
            'Nie udało się załadować profilu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sprawdź połączenie z internetem i spróbuj ponownie',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildProfileContent() {
    final user = _user!;
    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(user: user),

              VolunteerStatusCard(
                user: user,
                onVolunteerSignup: _handleVolunteerSignup,
              ),

              if (_shouldShowVolunteerApplicationButton())
                _buildVolunteerApplicationCard(),

              AchievementProgress(
                level: user.level,
                xpPoints: user.xpPoints,
                xpToNextLevel: user.xpToNextLevel,
              ),
              QuickStats(user: user),
              Achievements(achievements: _recentAchievements),
              ActiveAchievements(user: user),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVolunteerApplicationCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volunteer_activism,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Zostań wolontariuszem',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pomóż zwierzętom w schroniskach poprzez spacery i opiekę. Złóż wniosek o zostanie wolontariuszem!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleVolunteerSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Złóż wniosek',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
      begin: 0.2,
      end: 0,
      duration: 300.ms,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 50,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'Twój profil',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.black),
          onPressed: _navigateToEditProfile,
          tooltip: 'Edytuj profil',
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black),
          onPressed: _onLogout,
          tooltip: 'Wyloguj',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}