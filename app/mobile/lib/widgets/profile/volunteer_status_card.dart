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
    // Nie wyświetlaj karty jeśli użytkownik nie jest wolontariuszem w ogóle
    if (_shouldShowVolunteerCard()) {
      return _buildVolunteerStatusCard();
    } else {
      return _buildVolunteerSignupCard();
    }
  }

  /// Określa czy pokazać kartę statusu wolontariusza
  bool _shouldShowVolunteerCard() {
    return user.volunteerStatus != null &&
        user.volunteerStatus != 'NONE';
  }

  /// Buduje kartę statusu wolontariusza
  Widget _buildVolunteerStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.1),
            _getStatusColor().withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status wolontariusza',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _getStatusText(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusBadge(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          if (_getStatusDescription() != null) ...[
            const SizedBox(height: 12),
            Text(
              _getStatusDescription()!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Buduje kartę zachęcającą do zostania wolontariuszem
  Widget _buildVolunteerSignupCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.volunteer_activism,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zostań wolontariuszem',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Text(
                      'Pomóż zwierzakom w schroniskach',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Jako wolontariusz będziesz mógł rezerwować wizyty w schroniskach, '
                'wyprowadzać psy na spacery i pomagać w opiece nad zwierzętami.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onVolunteerSignup,
              icon: const Icon(Icons.volunteer_activism, size: 18),
              label: const Text('Złóż wniosek o wolontariat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Zwraca kolor dla danego statusu
  Color _getStatusColor() {
    switch (user.volunteerStatus) {
      case 'PENDING':
        return Colors.orange;
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.red;
      default:
        return AppColors.primaryColor;
    }
  }

  /// Zwraca ikonę dla danego statusu
  IconData _getStatusIcon() {
    switch (user.volunteerStatus) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'ACTIVE':
        return Icons.check_circle;
      case 'INACTIVE':
        return Icons.pause_circle;
      default:
        return Icons.volunteer_activism;
    }
  }

  /// Zwraca tekst statusu
  String _getStatusText() {
    switch (user.volunteerStatus) {
      case 'PENDING':
        return 'Wniosek w trakcie rozpatrywania';
      case 'ACTIVE':
        return 'Aktywny wolontariusz';
      case 'INACTIVE':
        return 'Nieaktywny wolontariusz';
      default:
        return 'Nieznany status';
    }
  }

  /// Zwraca krótki badge statusu
  String _getStatusBadge() {
    switch (user.volunteerStatus) {
      case 'PENDING':
        return 'OCZEKUJE';
      case 'ACTIVE':
        return 'AKTYWNY';
      case 'INACTIVE':
        return 'NIEAKTYWNY';
      default:
        return 'NIEZNANY';
    }
  }

  /// Zwraca opis statusu (opcjonalny)
  String? _getStatusDescription() {
    switch (user.volunteerStatus) {
      case 'PENDING':
        return 'Twój wniosek o zostanie wolontariuszem jest obecnie rozpatrywany. '
            'Skontaktujemy się z Tobą wkrótce.';
      case 'ACTIVE':
        return 'Możesz teraz rezerwować wizyty w schroniskach i pomagać zwierzętom.';
      case 'INACTIVE':
        return 'Twoje konto wolontariusza jest nieaktywne. '
            'Skontaktuj się z administracją aby reaktywować.';
      default:
        return null;
    }
  }
}