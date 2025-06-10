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
    // Pokazuj kartę tylko gdy status jest różny od NONE lub null
    if (user.volunteerStatus == null || user.volunteerStatus == 'NONE') {
      return const SizedBox.shrink(); // Nie wyświetlaj nic
    }

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