import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api/initial_api.dart';
import '../services/token_repository.dart';
import '../services/preloader/app_preloader.dart';
import '../styles/colors.dart';
import 'auth/welcome_view.dart';
import 'home_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  PreloadProgress? _currentProgress;
  bool _isLoggedIn = false;
  String _statusMessage = 'Ładowanie...';

  final AppPreloader _preloader = AppPreloader();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startLoadingSequence();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoController.forward();
  }

  Future<void> _startLoadingSequence() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/dogs_collage.jpg'), context);
    });

    await _checkLoginStatus();

    if (_isLoggedIn) {
      _listenToPreloadProgress();
      await _preloader.preloadEssentialData();

      await Future.delayed(Duration(milliseconds: 800));
      _goToHome();
    } else {
      await Future.delayed(Duration(milliseconds: 1500));
      _goToWelcome();
    }
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _statusMessage = 'Sprawdzanie logowania...';
    });

    final token = await TokenRepository().getToken();
    if (token == null) {
      _isLoggedIn = false;
      return;
    }

    try {
      final resp = await InitialApi().dio.post(
        '/auth/token/validate',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (resp.statusCode == 200 && resp.data['valid'] == true) {
        _isLoggedIn = true;
        setState(() {
          _statusMessage = 'Przygotowywanie aplikacji...';
        });
      } else {
        await TokenRepository().removeToken();
        _isLoggedIn = false;
      }
    } on DioException catch (e) {
      dev.log('Token validation failed: ${e.message}');
      await TokenRepository().removeToken();
      _isLoggedIn = false;
    }
  }

  void _listenToPreloadProgress() {
    _preloader.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentProgress = progress;
          _statusMessage = progress.stepName;
        });
        _progressController.animateTo(progress.progress);
      }
    });
  }

  void _goToHome() {
    if (!mounted) return;

    _preloader.predictivePreload();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  void _goToWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const WelcomeView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) =>
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(
                                Icons.pets,
                                color: AppColors.primaryColor.withOpacity(0.7),
                                size: 32,
                              ),
                            )
                        ).animate(interval: 200.ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.5, duration: 600.ms)
                            .then(delay: 1000.ms)
                            .shimmer(duration: 2000.ms, color: AppColors.primaryColor.withOpacity(0.3)),
                      ),

                      const SizedBox(height: 40),

                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/logo.svg',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      Text(
                        'Petify',
                        style: GoogleFonts.pacifico(
                          fontSize: 48,
                          color: AppColors.primaryColor,
                          shadows: [
                            const Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ).animate(delay: 500.ms)
                          .fadeIn(duration: 800.ms)
                          .slideY(begin: 0.3, duration: 800.ms, curve: Curves.easeOut),

                      const SizedBox(height: 20),

                      Text(
                        'Znajdź swojego najlepszego przyjaciela',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 1000.ms)
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.2, duration: 600.ms),
                    ],
                  ),
                ),
              ),

              if (_isLoggedIn) ...[
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _progressController.value,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                            minHeight: 4,
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: Text(
                          _statusMessage,
                          key: ValueKey(_statusMessage),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (_currentProgress != null)
                        Text(
                          '${(_currentProgress!.progress * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ).animate(delay: 1500.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, duration: 500.ms),
              ] else ...[
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  strokeWidth: 3,
                ).animate(delay: 1500.ms)
                    .fadeIn(duration: 500.ms)
                    .scale(duration: 500.ms),

                const SizedBox(height: 16),

                Text(
                  _statusMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: 1700.ms)
                    .fadeIn(duration: 500.ms),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}