import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api/initial_api.dart';
import '../services/token_repository.dart';
import '../services/user_service.dart';
import '../styles/colors.dart';
import 'auth/welcome_view.dart';
import 'home_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/dogs_collage.jpg'), context);
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final token = await TokenRepository().getToken();
    if (token == null) {
      _goToWelcome();
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
        // final profileResp = await UserService().getCurrentUser();
        _goToHome();
      } else {
        await TokenRepository().removeToken();
        _goToWelcome();
      }
    } on DioException catch (e) {
      // niepoprawny lub wygasły token
      await TokenRepository().removeToken();
      _goToWelcome();
    }
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeView()),
    );
  }

  void _goToWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimateList(
            interval: 300.ms,
            effects: [
              ScaleEffect(curve: Curves.easeOutBack, duration: 800.ms),
              FadeEffect(duration: 800.ms),
            ],
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                      (_) => const Icon(Icons.pets, color: AppColors.primaryColor, size: 40),
                ).animate(interval: 200.ms).fadeIn(duration: 600.ms).slideY(begin: 0.5, duration: 600.ms),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryColor,
                child: const Icon(Icons.pets, color: Colors.white, size: 50),
              ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOutBack).scale(duration: 800.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text(
                'Petify',
                style: GoogleFonts.pacifico(
                  fontSize: 40,
                  color: AppColors.primaryColor,
                  shadows: [
                    const Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(3, 3)),
                  ],
                ),
              ).animate().fade(duration: 700.ms, delay: 400.ms).slideY(begin: 0.3, duration: 700.ms, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }
}
