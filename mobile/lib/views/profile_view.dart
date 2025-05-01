import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../widgets/profile/activity_tab.dart';
import '../widgets/profile/supported_pets_tab.dart';
import '../widgets/profile/donations_tab.dart';
import '../widgets/profile/notifications_sheet.dart';

// import 'edit_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _user;
  List<Achievement> _achievements = [];
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
      final userService = UserService();
      final achievementService = AchievementService();

      final userData = await userService.getCurrentUser();
      final achievements = await achievementService.getUserAchievements();

      if (mounted) {
        setState(() {
          _user = userData;
          _achievements = achievements.take(3).toList();
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
          SnackBar(content: Text('Nie udało się załadować profilu: $e')),
        );
      }
    }
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
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
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
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nie udało się załadować profilu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sprawdź połączenie z internetem i spróbuj ponownie',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildProfileContent() {
    if (_user == null) {
      return _buildLoadingView();
    }

    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(user: _user!),
              AchievementProgress(user: _user!),
              QuickStats(user: _user!),
              Achievements(
                achievements: _achievements,
              ),
              ActiveAchievements(),
              _buildTabBar(),
            ],
          ),
        ),
        _buildTabContent(),
      ],
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.black),
          onPressed: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => const EditProfileView()),
            // );
          },
          tooltip: 'Edytuj profil',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Aktywność'),
          Tab(text: 'Wsparcia'),
          Tab(text: 'Wpłaty'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_user == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final maxHeight = math.max(
      320.0,
      MediaQuery.of(context).size.height * .66,
    );

    return SliverToBoxAdapter(
      child: SizedBox(
        height: maxHeight,
        child: TabBarView(
          controller: _tabController,
          children: [
            ActivityTab(user: _user!),
            SupportedPetsTab(user: _user!),
            DonationsTab(user: _user!),
          ],
        ),
      ),
    );
  }
}