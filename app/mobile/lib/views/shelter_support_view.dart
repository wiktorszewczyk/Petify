import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/shelter_view.dart';
import '../models/shelter_model.dart';
import '../services/shelter_service.dart';
import '../styles/colors.dart';

class ShelterSupportView extends StatefulWidget {
  const ShelterSupportView({super.key});

  @override
  State<ShelterSupportView> createState() => _ShelterSupportViewState();
}

class _ShelterSupportViewState extends State<ShelterSupportView> {
  final ShelterService _shelterService = ShelterService();
  bool _isLoading = true;
  List<ShelterModel> _shelters = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShelters();
  }

  Future<void> _loadShelters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shelters = await _shelterService.getShelters();
      setState(() {
        _shelters = shelters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nie udało się pobrać listy schronisk. Spróbuj ponownie później.';
        _isLoading = false;
      });
    }
  }

  void _navigateToShelterDetails(ShelterModel shelter) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShelterView(shelter: shelter)),
    );
  }

  void _supportShelter(ShelterModel shelter) {
    // TODO: Implementacja wsparcia schroniska
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Przejście do ekranu wsparcia schroniska ${shelter.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pomóż schroniskom',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadShelters,
        color: AppColors.primaryColor,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_shelters.isEmpty) {
      return _buildEmptyView();
    }

    return _buildSheltersList();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Ładowanie schronisk...',
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadShelters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Spróbuj ponownie',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Brak schronisk do wyświetlenia',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Spróbuj odświeżyć stronę lub sprawdź połączenie z internetem',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheltersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shelters.length,
      itemBuilder: (context, index) {
        final shelter = _shelters[index];
        return _buildShelterCard(shelter, index);
      },
    );
  }

  Widget _buildShelterCard(ShelterModel shelter, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToShelterDetails(shelter),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shelter.isUrgent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Text(
                    'PILNA POTRZEBA POMOCY',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.network(
                        shelter.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(Icons.image_not_supported,
                                    color: Colors.grey[400]),
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shelter.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shelter.address,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.pets, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${shelter.petsCount} zwierząt',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.volunteer_activism,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${shelter.volunteersCount} wolontariuszy',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (shelter.donationGoal > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cel zbiórki: ${shelter.donationGoal.toInt()} PLN',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${shelter.donationPercentage.toInt()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: shelter.donationPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shelter.needs.isNotEmpty) ...[
                    Text(
                      'Potrzeby:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: shelter.needs
                          .take(3)
                          .map(
                            (need) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            need,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                    if (shelter.needs.length > 3) ...[
                      const SizedBox(height: 8),
                      Text(
                        '+ ${shelter.needs.length - 3} więcej...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _navigateToShelterDetails(shelter),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Szczegóły',
                            style: GoogleFonts.poppins(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _supportShelter(shelter),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Wesprzyj',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
      begin: 0.2,
      end: 0,
      duration: 300.ms,
      delay: (50 * index).ms,
      curve: Curves.easeOutCubic,
    );
  }
}