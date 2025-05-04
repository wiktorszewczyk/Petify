import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../styles/colors.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.33,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/dogs_collage.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.pets, color: AppColors.primaryColor, size: 32),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 10),

          Text(
            'Petify',
            style: GoogleFonts.pacifico(
              fontSize: 36,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 6, offset: const Offset(2, 2)),
              ],
            ),
          ).animate()
              .fadeIn(duration: 700.ms, delay: 200.ms)
              .slide(begin: const Offset(0, 0.2), duration: 700.ms, curve: Curves.easeOut),
        ],
      ),
    )
        .animate().fadeIn(duration: 500.ms, curve: Curves.easeIn);
  }
}
