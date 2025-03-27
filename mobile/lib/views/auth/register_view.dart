import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/colors.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_textfield.dart';
import '../../widgets/clippers/top_wave_clipper.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Nagłówek dekoracyjny
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
                      'Dołącz do Petify i pomóż zwierzakom',
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
                  const SizedBox(height: 15),
                  const CustomTextField(labelText: 'Powtórz hasło', obscureText: true),
                  const SizedBox(height: 30),
                  PrimaryButton(
                    text: 'Zarejestruj się',
                    onPressed: () {
                      // TODO: Backend rejestracja
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Masz już konto? Zaloguj się',
                      style: TextStyle(color: AppColors.textColor),
                    ),
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
