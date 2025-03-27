import 'package:flutter/material.dart';
import 'register_view.dart';
import '../../styles/colors.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_textfield.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/clippers/top_wave_clipper.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Górna dekoracja
            ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                width: double.infinity,
                height: screenHeight * 0.3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFB74D),
                      AppColors.primaryColor,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.pets, color: AppColors.primaryColor, size: 30),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Petify',
                      style: GoogleFonts.pacifico(
                        fontSize: 36,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Znajdź swojego najlepszego przyjaciela',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const CustomTextField(labelText: 'Email'),
                  const SizedBox(height: 15),
                  const CustomTextField(labelText: 'Hasło', obscureText: true),
                  const SizedBox(height: 30),
                  PrimaryButton(
                    text: 'Zaloguj się',
                    onPressed: () {
                      // TODO: Backend login
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 300),
                          pageBuilder: (_, __, ___) => const RegisterScreen(),
                          transitionsBuilder: (_, animation, __, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                ),
                                child: child,
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('Nie masz konta? Zarejestruj się',
                                      style: TextStyle(color: AppColors.textColor)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
