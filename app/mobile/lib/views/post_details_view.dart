import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import '../models/shelter_post.dart';
import '../models/shelter.dart';
import '../models/donation.dart';
import '../services/image_service.dart';
import '../services/shelter_service.dart';
import '../services/payment_service.dart';
import '../services/cache/cache_manager.dart';
import '../styles/colors.dart';
import 'payment_view.dart';

class PostDetailsView extends StatefulWidget {
  final ShelterPost post;

  const PostDetailsView({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailsView> createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends State<PostDetailsView> {
  final _imageService = ImageService();
  final _shelterService = ShelterService();
  final _paymentService = PaymentService();

  List<ImageResponse> _additionalImages = [];
  bool _isLoadingImages = false;
  Shelter? _shelter;
  bool _isLoadingShelter = false;
  FundraiserResponse? _fundraiser;
  bool _isLoadingFundraiser = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadAdditionalData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAdditionalData() async {
    await Future.wait([
      _loadAdditionalImages(),
      _loadShelterInfo(),
      _loadFundraiserInfo(),
    ]);
  }

  Future<void> _loadAdditionalImages() async {
    if (widget.post.imageIds == null || widget.post.imageIds!.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingImages = true;
    });

    try {
      final images = await _imageService.getImagesByIds(widget.post.imageIds!);
      setState(() {
        _additionalImages = images;
        _isLoadingImages = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingImages = false;
      });
      print('❌ PostDetailsView: Błąd podczas ładowania obrazów: $e');
    }
  }

  Future<void> _loadShelterInfo() async {
    if (widget.post.shelterId == null) {
      return;
    }

    setState(() {
      _isLoadingShelter = true;
    });

    try {
      final shelter = await _shelterService.getShelterById(widget.post.shelterId!);
      setState(() {
        _shelter = shelter;
        _isLoadingShelter = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingShelter = false;
      });
      print('❌ PostDetailsView: Błąd podczas ładowania danych schroniska: $e');
    }
  }

  Future<void> _loadFundraiserInfo() async {
    if (widget.post.fundraisingId == null) {
      return;
    }

    setState(() {
      _isLoadingFundraiser = true;
    });

    try {
      final fundraiser = await _paymentService.getFundraiser(widget.post.fundraisingId!);
      setState(() {
        _fundraiser = fundraiser;
        _isLoadingFundraiser = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFundraiser = false;
      });
      print('❌ PostDetailsView: Błąd podczas ładowania danych zbiórki: $e');
    }
  }

  Future<void> _sharePost() async {
    try {
      await Share.share(
        'Sprawdź to ogłoszenie ze schroniska!\n\n'
            '${widget.post.title}\n\n'
            '${widget.post.description}\n\n'
            'Udostępnione z aplikacji Petify',
        subject: widget.post.title,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się udostępnić: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _donateToFundraiser() async {
    if (_fundraiser == null || widget.post.shelterId == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentView(
          shelterId: widget.post.shelterId!,
          shelter: _shelter,
          fundraiserId: _fundraiser!.id,
          initialAmount: 20.0,
          title: 'Wspieraj: ${_fundraiser!.title}',
          description: _fundraiser!.description,
        ),
      ),
    );

    if (result == true && mounted) {
      // Invalidate cache po donacji
      CacheManager.invalidatePattern('shelter_');
      CacheManager.invalidatePattern('fundraiser_');
      CacheManager.invalidatePattern('user_donations');
      CacheManager.invalidatePattern('posts_');
      print('🗑️ PostDetailsView: Invalidated cache after fundraiser donation');

      // Uruchom konfetti przy sukcesie!
      _confettiController.play();

      await _loadFundraiserInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dziękujemy za wsparcie!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              'Ogłoszenie',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
            actions: [
              IconButton(
                onPressed: _sharePost,
                icon: const Icon(Icons.share),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pokaż główne zdjęcie tylko jeśli mainImageId istnieje
                if (widget.post.mainImageId != null) _buildMainImage(),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.title,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildShelterInfo(),
                      const SizedBox(height: 16),

                      if (_fundraiser != null) ...[
                        _buildFundraiserCard(),
                        const SizedBox(height: 24),
                      ],

                      if (widget.post.description.isNotEmpty) ...[
                        Text(
                          'Opis',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.post.description,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_additionalImages.isNotEmpty) ...[
                        Text(
                          'Galeria',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildImageGallery(),
                        const SizedBox(height: 24),
                      ],

                      _buildActionButtons(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.orange,
              Colors.purple,
              Colors.red,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainImage() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: Image.network(
        widget.post.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  'Nie udało się załadować obrazu',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShelterInfo() {
    return Row(
      children: [
        Icon(
          Icons.home,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _shelter?.name ?? widget.post.shelterName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(widget.post.date),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    if (_isLoadingImages) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _additionalImages.length,
        itemBuilder: (context, index) {
          final image = _additionalImages[index];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showImageFullscreen(image.imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 120,
                  height: 120,
                  child: Image.network(
                    image.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFundraiserCard() {
    if (_fundraiser == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(
                Icons.volunteer_activism,
                color: AppColors.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _fundraiser!.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _fundraiser!.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
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
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_fundraiser!.currentAmount.toInt()} PLN',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
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
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_fundraiser!.goalAmount.toInt()} PLN',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _fundraiser!.progressPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_fundraiser!.progressPercentage.toInt()}% celu osiągnięte',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _donateToFundraiser,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Wesprzyj zbiórkę',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _sharePost,
        icon: const Icon(Icons.share),
        label: Text(
          'Udostępnij',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primaryColor),
          foregroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _showImageFullscreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nie udało się załadować obrazu',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Dzisiaj';
    } else if (difference.inDays == 1) {
      return 'Wczoraj';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dni temu';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}