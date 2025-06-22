import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/shelter_view.dart';
import 'package:mobile/views/payment_view.dart';
import '../models/shelter.dart';
import '../models/donation.dart';
import '../services/shelter_service.dart';
import '../services/payment_service.dart';
import '../services/cache/cache_manager.dart';
import '../styles/colors.dart';

class ShelterSupportView extends StatefulWidget {
  const ShelterSupportView({super.key});

  @override
  State<ShelterSupportView> createState() => _ShelterSupportViewState();
}

class _ShelterSupportViewState extends State<ShelterSupportView> {
  final ShelterService _shelterService = ShelterService();
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  List<Shelter> _shelters = [];
  Map<int, FundraiserResponse?> _shelterFundraisers = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSheltersAndFundraisers();
  }

  Future<void> _loadSheltersAndFundraisers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      CacheManager.markStalePattern('shelter_');
      CacheManager.markStalePattern('fundraiser_');
      print('🔄 ShelterSupportView: Refreshing shelters and fundraisers data...');

      final shelters = await _shelterService.getShelters();
      final fundraisers = <int, FundraiserResponse?>{};

      for (final shelter in shelters) {
        try {
          final fundraiser = await _paymentService.getShelterMainFundraiser(shelter.id);
          fundraisers[shelter.id] = fundraiser;
        } catch (e) {
          fundraisers[shelter.id] = null;
        }
      }


      if (mounted) {
        setState(() {
          _shelters = shelters;
          _shelterFundraisers = fundraisers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Nie udało się pobrać listy schronisk: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToShelterDetails(Shelter shelter) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShelterView(shelter: shelter)),
    );

    if (result == true && mounted) {
      _loadSheltersAndFundraisers();
    }
  }

  void _supportShelter(Shelter shelter) async {
    final fundraiser = _shelterFundraisers[shelter.id];
    final useFundraiser = fundraiser?.canAcceptDonations == true;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentView(
          shelterId: shelter.id,
          shelter: shelter,
          fundraiserId: useFundraiser ? fundraiser!.id : null,
          initialAmount: 20.0,
          title: useFundraiser
              ? 'Wspieraj: ${fundraiser!.title}'
              : 'Wspieraj schronisko: ${shelter.name}',
          description: useFundraiser
              ? fundraiser!.description
              : 'Ogólne wsparcie dla schroniska na bieżące potrzeby',
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadSheltersAndFundraisers();
    }
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
        onRefresh: _loadSheltersAndFundraisers,
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
              onPressed: _loadSheltersAndFundraisers,
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

  Widget _buildShelterCard(Shelter shelter, int index) {
    final fundraiser = _shelterFundraisers[shelter.id];

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
            if (shelter.isUrgent == true)
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
                      child: _buildShelterImage(shelter.finalImageUrl),
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
                        if (shelter.address != null) ...[
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shelter.address!,
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
                        ],
                        Row(
                          children: [
                            Icon(Icons.pets, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${shelter.petsCount ?? 0} zwierząt',
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

            if (fundraiser != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fundraiser.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Zebrano: ${fundraiser.currentAmount.toInt()} PLN',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Cel: ${fundraiser.goalAmount.toInt()} PLN',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: fundraiser.progressPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fundraiser.progressPercentage.toInt()}% celu',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (shelter.needs != null && shelter.needs!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Potrzeby:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shelter.needs!.take(3).join(', '),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                          fontSize: 13,
                        ),
                      ),
                    ),
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

  Widget _buildShelterImage(String imageUrl) {
    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64String = imageUrl.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        );
      } catch (e) {
        return _buildPlaceholderImage();
      }
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
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
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
      );
    }

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Image.asset(
      'assets/images/default_shelter.jpg',
      fit: BoxFit.cover,
    );
  }
}