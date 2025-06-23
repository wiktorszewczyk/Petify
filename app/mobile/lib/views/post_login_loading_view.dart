import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/preloader/app_preloader.dart';
import '../styles/colors.dart';
import 'home_view.dart';

class PostLoginLoadingView extends StatefulWidget {
  const PostLoginLoadingView({super.key});

  @override
  State<PostLoginLoadingView> createState() => _PostLoginLoadingViewState();
}

class _PostLoginLoadingViewState extends State<PostLoginLoadingView>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  PreloadProgress? _currentProgress;
  String _statusMessage = 'Przygotowujemy Twoją aplikację...';

  final AppPreloader _preloader = AppPreloader();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startPreloading();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoController.forward();
  }

  Future<void> _startPreloading() async {
    _listenToPreloadProgress();

    await _preloader.preloadEssentialData();

    // Skrócone delay dla lepszej responsywności
    await Future.delayed(Duration(milliseconds: 300));

    _goToHome();
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
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ).animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 400.ms),

                      const SizedBox(height: 30),

                      Text(
                        'Witamy z powrotem!',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 400.ms)
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.3, duration: 600.ms),

                      const SizedBox(height: 40),

                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/logo.svg',
                                    width: 60,
                                    height: 60,
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
                          fontSize: 36,
                          color: AppColors.primaryColor,
                          shadows: [
                            const Shadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ).animate(delay: 800.ms)
                          .fadeIn(duration: 600.ms)
                          .shimmer(delay: 1200.ms, duration: 2000.ms, color: AppColors.primaryColor.withOpacity(0.3)),
                    ],
                  ),
                ),
              ),

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
              ).animate(delay: 1000.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, duration: 500.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}