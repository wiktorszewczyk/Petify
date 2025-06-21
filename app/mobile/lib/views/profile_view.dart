import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/views/edit_profile_view.dart';
import 'package:mobile/views/volunteer_application_view.dart';
import 'package:shimmer/shimmer.dart';
import '../models/user.dart';
import '../models/achievement.dart';
import '../services/user_service.dart';
import '../services/achievement_service.dart';
import '../services/cache/cache_manager.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final needsRefresh = CacheManager.isStale('user_data') ||
          CacheManager.get<User>('user_data') == null;
      if (needsRefresh && mounted) {
        print('📱 ProfileView: App resumed, refreshing user data');
        _loadUserProfile();
      }
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      CacheManager.invalidatePattern('user_');
      CacheManager.invalidatePattern('current_user');
      CacheManager.invalidatePattern('achievements_');
      CacheManager.invalidatePattern('favorites');
      CacheManager.invalidatePattern('supported');

      print('🔄 ProfileView: Odświeżanie danych profilu i invalidacja cache...');

      final userData = await UserService().getCurrentUser();
      final allAchievements =
      await AchievementService().getUserAchievements();

      if (!mounted) return;
      setState(() {
        _user = userData;
        _recentAchievements = allAchievements
            .where((a) => a.isUnlocked)
            .toList()
          ..sort((a, b) =>
              b.dateAchieved!.compareTo(a.dateAchieved!));
        _recentAchievements = _recentAchievements.take(3).toList();
        _isLoading = false;
      });

      print('✅ ProfileView: Profil odświeżony pomyślnie');
    } catch (e) {
      print('❌ ProfileView: Błąd podczas odświeżania profilu: $e');
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

    if (result == true) {
      _loadUserProfile();
    }
  }

  Future<void> _confirmDeactivate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dezaktywacja konta'),
        content: const Text('Czy na pewno chcesz dezaktywować swoje konto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final resp = await UserService().deactivateAccount();
      if (!mounted) return;
      if (resp.statusCode == 200) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeView()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: ${resp.data}')),
        );
      }
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
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 20, width: double.infinity, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 16, width: 200, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 14, width: 120, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(2, (index) => Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            )),
          ],
        ),
      ),
    );
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
    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      color: AppColors.primaryColor,
      child: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextButton(
                    onPressed: _confirmDeactivate,
                    child: Text(
                      'Dezaktywuj konto',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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