import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/adoption.dart';
import '../services/application_service.dart';
import '../services/pet_service.dart';
import '../styles/colors.dart';

class MyApplicationsView extends StatefulWidget {
  const MyApplicationsView({super.key});

  @override
  State<MyApplicationsView> createState() => _MyApplicationsViewState();
}

class _MyApplicationsViewState extends State<MyApplicationsView> {
  final _applicationService = ApplicationService();
  final _petService = PetService();

  List<AdoptionResponse> _adoptionApplications = [];
  bool _isLoadingAdoptions = false;

  @override
  void initState() {
    super.initState();
    _loadAdoptionApplications();
  }

  Future<void> _loadAdoptionApplications() async {
    setState(() {
      _isLoadingAdoptions = true;
    });

    try {
      final applications = await _applicationService.getMyAdoptionApplications();
      setState(() {
        _adoptionApplications = applications;
        _isLoadingAdoptions = false;
      });

    } catch (e) {
      setState(() {
        _isLoadingAdoptions = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }


  Future<void> _cancelAdoptionApplication(AdoptionResponse adoption) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Anuluj wniosek',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Czy na pewno chcesz anulować wniosek adopcyjny?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nie'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tak, anuluj'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _applicationService.cancelAdoptionApplication(adoption.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wniosek został anulowany'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadAdoptionApplications();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się anulować wniosku: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Moje wnioski adopcyjne',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _buildAdoptionApplicationsView(),
    );
  }

  Widget _buildAdoptionApplicationsView() {
    return RefreshIndicator(
      onRefresh: _loadAdoptionApplications,
      child: _isLoadingAdoptions
          ? const Center(child: CircularProgressIndicator())
          : _adoptionApplications.isEmpty
          ? _buildEmptyState(
        icon: Icons.pets,
        title: 'Brak wniosków adopcyjnych',
        subtitle: 'Nie złożyłeś jeszcze żadnych wniosków o adopcję zwierzęcia',
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _adoptionApplications.length,
        itemBuilder: (context, index) {
          final adoption = _adoptionApplications[index];
          return _buildAdoptionCard(adoption);
        },
      ),
    );
  }


  Widget _buildAdoptionCard(AdoptionResponse adoption) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pets,
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
                        'Wniosek adopcyjny #${adoption.id}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Zwierzę ID: ${adoption.petId}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(adoption.adoptionStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    adoption.statusDisplayName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(adoption.adoptionStatus),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Dane kontaktowe: ${adoption.fullName}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (adoption.phoneNumber.isNotEmpty)
              Text(
                'Telefon: ${adoption.phoneNumber}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (adoption.adoptionStatus.toUpperCase() == 'PENDING')
                  OutlinedButton(
                    onPressed: () => _cancelAdoptionApplication(adoption),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Anuluj',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    _showAdoptionDetails(adoption);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Szczegóły',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAdoptionDetails(AdoptionResponse adoption) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Szczegóły wniosku adopcyjnego',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Status', adoption.statusDisplayName),
              _buildDetailRow('Imię i nazwisko', adoption.fullName),
              _buildDetailRow('Telefon', adoption.phoneNumber),
              _buildDetailRow('Adres', adoption.address),
              _buildDetailRow('Typ mieszkania', adoption.housingType),
              _buildDetailRow('Właściciel mieszkania', adoption.isHouseOwner ? 'Tak' : 'Nie'),
              _buildDetailRow('Posiada ogród', adoption.hasYard ? 'Tak' : 'Nie'),
              _buildDetailRow('Inne zwierzęta', adoption.hasOtherPets ? 'Tak' : 'Nie'),
              if (adoption.description != null && adoption.description!.isNotEmpty)
                _buildDetailRow('Opis', adoption.description!),
              const SizedBox(height: 16),
              Text(
                'Motywacja:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                adoption.motivationText,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}