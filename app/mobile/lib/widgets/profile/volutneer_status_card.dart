import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../styles/colors.dart';

class VolunteerStatusCard extends StatelessWidget {
  final User user;
  final VoidCallback onVolunteerSignup;

  const VolunteerStatusCard({
    Key? key,
    required this.user,
    required this.onVolunteerSignup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isVolunteer = user.role == 'VOLUNTEER';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVolunteer
              ? [Color(0xFF43A047), Color(0xFF66BB6A)]  // Green gradient for volunteers
              : [Color(0xFF5C6BC0), Color(0xFF3F51B5)], // Blue gradient for non-volunteers
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isVolunteer
                ? Colors.green.withOpacity(0.3)
                : AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: isVolunteer
            ? _buildVolunteerContent(context)
            : _buildNonVolunteerContent(context),
      ),
    );
  }

  Widget _buildVolunteerContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktywny Wolontariusz',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dziękujemy za Twoje zaangażowanie i pomoc zwierzakom!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildNonVolunteerContent(BuildContext context) {
    return InkWell(
      onTap: onVolunteerSignup,
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zostań Wolontariuszem',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pomóż zwierzakom w potrzebie i dołącz do naszej społeczności',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}