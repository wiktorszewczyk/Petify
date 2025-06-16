import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shelter_post.dart';
import '../models/shelter.dart';
import '../services/image_service.dart';
import '../services/shelter_service.dart';
import '../services/message_service.dart';
import '../styles/colors.dart';
import 'chat_view.dart';

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
  final _messageService = MessageService();

  List<ImageResponse> _additionalImages = [];
  bool _isLoadingImages = false;
  Shelter? _shelter;
  bool _isLoadingShelter = false;

  @override
  void initState() {
    super.initState();
    _loadAdditionalData();
  }

  Future<void> _loadAdditionalData() async {
    // Równoległe ładowanie obrazów i danych schroniska
    await Future.wait([
      _loadAdditionalImages(),
      _loadShelterInfo(),
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

  Future<void> _contactShelter() async {
    if (_shelter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się załadować danych schroniska'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Utwórz pokój czatu dla schroniska (nie dla konkretnego zwierzęcia)
      final chatRoom = await _messageService.createOrGetShelterChatRoom(_shelter!.id);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatView(
              chatRoomId: chatRoom['id']?.toString(),
              recipientName: _shelter!.name,
              context: 'Ogłoszenie: ${widget.post.title}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się nawiązać kontaktu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // Główne zdjęcie
            _buildMainImage(),

            // Zawartość posta
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tytuł
                  Text(
                    widget.post.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Informacje o schronisku i dacie
                  _buildShelterInfo(),
                  const SizedBox(height: 16),

                  // Opis
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

                  // Galeria dodatkowych zdjęć
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

                  // Akcje
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImage() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: widget.post.imageUrl.isNotEmpty
          ? Image.network(
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
      )
          : Container(
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 50,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'Brak zdjęcia',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _contactShelter,
            icon: const Icon(Icons.chat),
            label: Text(
              'Skontaktuj się',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
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
      ],
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