import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/shelter.dart';
import '../models/donation.dart';
import '../services/payment_service.dart';
import '../services/shelter_service.dart';
import '../views/payment_view.dart';
import '../styles/colors.dart';

class ShelterView extends StatefulWidget {
  final Shelter shelter;

  const ShelterView({
    Key? key,
    required this.shelter,
  }) : super(key: key);

  @override
  State<ShelterView> createState() => _ShelterViewState();
}

class _ShelterViewState extends State<ShelterView> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  final PaymentService _paymentService = PaymentService();
  final ShelterService _shelterService = ShelterService();
  FundraiserResponse? _mainFundraiser;
  bool _isLoadingFundraiser = true;
  bool _isRefreshing = false;
  List<String> _shelterImages = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadShelterData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showTitle) {
      setState(() {
        _showTitle = true;
      });
    } else if (_scrollController.offset <= 200 && _showTitle) {
      setState(() {
        _showTitle = false;
      });
    }
  }

  Future<void> _loadShelterData() async {
    setState(() {
      _isLoadingFundraiser = true;
    });

    try {
      // Load fundraiser data
      final fundraiser = await _paymentService.getShelterMainFundraiser(widget.shelter.id);

      // Extract shelter images from the shelter model
      final images = <String>[];

      // Priority 1: imageUrl from backend
      if (widget.shelter.imageUrl != null && widget.shelter.imageUrl!.isNotEmpty) {
        images.add(widget.shelter.imageUrl!);
      }
      // Priority 2: imageData (base64)
      else if (widget.shelter.imageData != null && widget.shelter.imageData!.isNotEmpty) {
        final mimeType = widget.shelter.imageType ?? 'image/jpeg';
        if (widget.shelter.imageData!.startsWith('data:image')) {
          images.add(widget.shelter.imageData!);
        } else {
          images.add('data:$mimeType;base64,${widget.shelter.imageData}');
        }
      }

      // TODO: Add support for shelter image gallery when backend provides it
      // For now we only have the main image

      if (mounted) {
        setState(() {
          _mainFundraiser = fundraiser;
          _shelterImages = images;
          _isLoadingFundraiser = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFundraiser = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshShelterData() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadShelterData();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie można otworzyć: $url')),
      );
    }
  }

  void _donateToFundraiser() async {
    if (_mainFundraiser != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentView(
            shelterId: widget.shelter.id,
            fundraiserId: _mainFundraiser!.id,
            initialAmount: 20.0,
            title: 'Wspieraj: ${_mainFundraiser!.title}',
            description: _mainFundraiser!.description,
          ),
        ),
      );

      // Refresh data after successful donation
      if (result == true) {
        await _refreshShelterData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dziękujemy za wsparcie!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _donateToShelter() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentView(
          shelterId: widget.shelter.id,
          initialAmount: 20.0,
          title: 'Wspieraj schronisko: ${widget.shelter.name}',
          description: 'Ogólne wsparcie dla schroniska na bieżące potrzeby',
        ),
      ),
    );

    // Refresh data after successful donation
    if (result == true) {
      await _refreshShelterData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dziękujemy za wsparcie!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareShelter() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funkcja udostępniania będzie dostępna wkrótce')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshShelterData,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.shelter.isUrgent == true)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red[400],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'PILNA POTRZEBA POMOCY',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms).moveY(begin: 20, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

                        // Shelter basic info
                        Text(
                          widget.shelter.name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 500.ms).moveY(begin: 20, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
                        const SizedBox(height: 8),

                        // Real data only - no placeholders
                        _buildInfoRow(Icons.location_on_outlined, widget.shelter.address),
                        _buildInfoRow(Icons.phone_outlined, widget.shelter.phoneNumber),
                        _buildInfoRow(Icons.email_outlined, widget.shelter.email),
                        if (widget.shelter.website != null)
                          _buildInfoRow(
                            Icons.language_outlined,
                            widget.shelter.website!,
                            onTap: () => _launchUrl('https://${widget.shelter.website}'),
                          ),

                        const SizedBox(height: 24),

                        // Improved stats section with better styling
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryColor.withOpacity(0.1),
                                AppColors.primaryColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets, size: 32, color: AppColors.primaryColor),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.shelter.petsCount ?? 0}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  Text(
                                    'Zwierząt czeka na dom',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms).scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        ),

                        const SizedBox(height: 24),

                        // Main fundraiser card - only if exists
                        if (_mainFundraiser != null) ...[
                          _buildMainFundraiserCard(),
                          const SizedBox(height: 24),
                        ],

                        // About section
                        if (widget.shelter.description != null && widget.shelter.description!.isNotEmpty) ...[
                          Text(
                            'O schronisku',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.shelter.description!,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Needs list - only if exists
                        _buildNeedsList(),

                        // Contact section
                        _buildContactSection(),

                        const SizedBox(height: 120), // More space for bottom buttons
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Always visible back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
          // Fixed bottom buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _donateToShelter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Wesprzyj',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _shareShelter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.primaryColor),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.share, color: AppColors.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Udostępnij',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      title: _showTitle
          ? Text(
        widget.shelter.name,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      )
          : null,
      backgroundColor: AppColors.primaryColor,
      automaticallyImplyLeading: false, // Remove default back button
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'shelter_image_${widget.shelter.id}',
              child: _buildShelterImage(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            // Image gallery indicator (if multiple images)
            if (_shelterImages.length > 1)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_shelterImages.length}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelterImage() {
    // Use images from backend if available
    if (_shelterImages.isNotEmpty) {
      final imageUrl = _shelterImages.first;

      // Handle Base64 images from backend
      if (imageUrl.startsWith('data:image/')) {
        try {
          final base64String = imageUrl.split(',')[1];
          return GestureDetector(
            onTap: _shelterImages.length > 1 ? _showImageGallery : null,
            child: Image.memory(
              base64Decode(base64String),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
            ),
          );
        } catch (e) {
          return _buildPlaceholderImage();
        }
      }

      // Handle network URLs
      if (imageUrl.startsWith('http')) {
        return GestureDetector(
          onTap: _shelterImages.length > 1 ? _showImageGallery : null,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
          ),
        );
      }
    }

    return _buildPlaceholderImage();
  }

  void _showImageGallery() {
    // TODO: Implement image gallery when backend provides multiple images
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Galeria zdjęć będzie dostępna wkrótce')),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[300]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Brak zdjęcia schroniska',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String? text, {VoidCallback? onTap}) {
    // Jeśli text jest null lub pusty, nie wyświetlaj wiersza
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: onTap != null ? AppColors.primaryColor : Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: row,
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
      begin: const Offset(0.9, 0.9),
      end: const Offset(1, 1),
      duration: 600.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildMainFundraiserCard() {
    if (_isLoadingFundraiser) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.8),
            AppColors.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'GŁÓWNA ZBIÓRKA',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _mainFundraiser!.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _mainFundraiser!.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zebrano',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '${_mainFundraiser!.currentAmount.toInt()} PLN',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Cel',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '${_mainFundraiser!.goalAmount.toInt()} PLN',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _mainFundraiser!.progressPercentage / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_mainFundraiser!.progressPercentage.toInt()}% celu',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_mainFundraiser!.canAcceptDonations)
                GestureDetector(
                  onTap: _donateToFundraiser,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, color: AppColors.primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Wspieram',
                          style: GoogleFonts.poppins(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 700.ms).moveY(begin: 20, end: 0, duration: 700.ms, curve: Curves.easeOutCubic);
  }


  Widget _buildNeedsList() {
    if (widget.shelter.needs == null || widget.shelter.needs!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Potrzeby schroniska',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.shelter.needs!.map((need) => _buildNeedItem(need)).toList(),
      ],
    );
  }

  Widget _buildNeedItem(String need) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              need,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kontakt',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (widget.shelter.phoneNumber != null) ...[
              Expanded(
                child: InkWell(
                  onTap: () => _launchUrl('tel:${widget.shelter.phoneNumber}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.phone, color: AppColors.primaryColor),
                        const SizedBox(height: 8),
                        Text(
                          'Zadzwoń',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (widget.shelter.email != null) ...[
              Expanded(
                child: InkWell(
                  onTap: () => _launchUrl('mailto:${widget.shelter.email}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.email, color: AppColors.primaryColor),
                        const SizedBox(height: 8),
                        Text(
                          'Email',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (widget.shelter.address != null)
              Expanded(
                child: InkWell(
                  onTap: () => _launchUrl('https://maps.google.com/?q=${widget.shelter.address}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.map, color: AppColors.primaryColor),
                        const SizedBox(height: 8),
                        Text(
                          'Mapa',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

}