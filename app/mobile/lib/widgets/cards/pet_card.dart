import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../models/pet.dart';
import '../../styles/colors.dart';
import '../../views/chat_view.dart';
import '../../services/message_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PetCard extends StatefulWidget {
  final Pet pet;

  const PetCard({
    super.key,
    required this.pet,
  });

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> with AutomaticKeepAliveClientMixin {
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();
  final MessageService _messageService = MessageService();

  // Cache dla obrazów - zapobiega mruganiu
  final Map<String, ImageProvider> _imageCache = {};
  static final Map<String, ImageProvider> _globalImageCache = {};
  bool _isImageLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _preloadImages();
  }

  void _preloadImages() {
    final allImages = _getAllImages();
    for (int i = 0; i < allImages.length; i++) {
      final imagePath = allImages[i];

      // Sprawdz globalny cache najpierw
      if (_globalImageCache.containsKey(imagePath)) {
        _imageCache[imagePath] = _globalImageCache[imagePath]!;
        if (i == 0) {
          setState(() {
            _isImageLoaded = true;
          });
        }
        continue;
      }

      final imageProvider = _getImageProvider(imagePath);
      if (imageProvider != null) {
        _imageCache[imagePath] = imageProvider;
        _globalImageCache[imagePath] = imageProvider; // Dodaj do globalnego cache

        // Preload pierwsze 2 obrazy dla lepszej wydajności
        if (i < 2) {
          imageProvider.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener((info, _) {
              if (mounted && i == 0) {
                setState(() {
                  _isImageLoaded = true;
                });
              }
            }),
          );
        }
      }
    }
  }

  ImageProvider? _getImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }

    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }

    return null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPhoto() {
    if (_currentPhotoIndex < widget.pet.galleryImages.length) {
      HapticFeedback.selectionClick(); // Dodaj haptic feedback
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut, // Bardziej sprężysta animacja
      );
    }
  }

  void _goToPreviousPhoto() {
    if (_currentPhotoIndex > 0) {
      HapticFeedback.selectionClick(); // Dodaj haptic feedback
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut, // Bardziej sprężysta animacja
      );
    }
  }

  List<String> _getAllImages() {
    return [widget.pet.imageUrlSafe, ...widget.pet.galleryImages];
  }

  Widget _getImageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    // Używaj CachedNetworkImage dla lepszej wydajności
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            color: Colors.white,
            child: Center(
              child: Icon(Icons.pets, size: 50, color: Colors.grey[400]),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildErrorImage(),
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      );
    }

    return _buildErrorImage();
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(Icons.pets, size: 50, color: Colors.grey[600]),
      ),
    );
  }

  void _shareProfile() {
    final petLink = "https://petify.com/pet/${widget.pet.id}";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Udostępnij profil ${widget.pet.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildShareOption(
              context,
              icon: Icons.link,
              color: Colors.blue,
              title: 'Skopiuj link',
              onTap: () {
                Clipboard.setData(ClipboardData(text: petLink));
                Navigator.pop(context);
                _showShareConfirmation(context, 'Link skopiowany do schowka');
              },
            ),

            _buildShareOption(
              context,
              icon: Icons.facebook,
              color: Color(0xFF1877F2),
              title: 'Facebook',
              onTap: () {
                _shareToSocialMedia('facebook', petLink);
                Navigator.pop(context);
              },
            ),

            _buildShareOption(
              context,
              icon: Icons.camera_alt,
              color: Color(0xFFE1306C),
              title: 'Instagram',
              onTap: () {
                _shareToSocialMedia('instagram', petLink);
                Navigator.pop(context);
              },
            ),

            _buildShareOption(
              context,
              icon: Icons.chat_bubble,
              color: Color(0xFF25D366),
              title: 'WhatsApp',
              onTap: () {
                _shareToSocialMedia('whatsapp', petLink);
                Navigator.pop(context);
              },
            ),

            _buildShareOption(
              context,
              icon: Icons.share,
              color: Colors.orange,
              title: 'Inne',
              onTap: () {
                Share.share(
                  'Poznaj ${widget.pet.name}! Czeka '
                      'na adopcję w ${widget.pet.shelterName}. ${petLink}',
                  subject: 'Zwierzak do adopcji: ${widget.pet.name}',
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showShareConfirmation(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareToSocialMedia(String platform, String link) {
    final text = 'Poznaj ${widget.pet.name}! ${widget.pet.gender == 'male' ? 'Czeka' : 'Czeka'} '
        'na adopcję w ${widget.pet.shelterName}. $link';

    switch (platform) {
      case 'facebook':
        Share.share('$text #adopcjazwierząt');
        break;
      case 'instagram':
        Share.share('$text #adopcjazwierząt #schronisko');
        break;
      case 'whatsapp':
        final whatsappUrl = 'whatsapp://send?text=${Uri.encodeComponent(text)}';
        launchUrl(Uri.parse(whatsappUrl)).catchError((error) {
          Share.share(text);
        });
        break;
      default:
        Share.share(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final allImages = [widget.pet.imageUrlSafe, ...widget.pet.galleryImages];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Używamy RepaintBoundary, żeby zapobiec niepotrzebnemu odświeżaniu
                RepaintBoundary(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPhotoIndex = index;
                      });
                    },
                    itemCount: allImages.length,
                    itemBuilder: (context, index) {
                      final imagePath = allImages[index];

                      return Hero(
                        tag: index == 0 ? 'pet_${widget.pet.id}' : 'pet_${widget.pet.id}_$index',
                        child: _getImageWidget(imagePath),
                      );
                    },
                  ),
                ),

                if (allImages.length > 1) ...[
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _currentPhotoIndex > 0 ? _goToPreviousPhoto : null,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: double.infinity,
                          color: Colors.transparent,
                          child: _currentPhotoIndex > 0
                              ? Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 25,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _currentPhotoIndex < allImages.length - 1 ? _goToNextPhoto : null,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: double.infinity,
                          color: Colors.transparent,
                          child: _currentPhotoIndex < allImages.length - 1
                              ? Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 25,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],

                if (allImages.length > 1)
                  Positioned(
                    bottom: 90,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        allImages.length,
                            (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPhotoIndex == index
                                ? AppColors.primaryColor
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AutoSizeText(
                              widget.pet.name,
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              minFontSize: 18,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDisplayAge(widget.pet.age),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          if (widget.pet.isVaccinated)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Zaszczepiony',
                                    style: TextStyle(
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.pet.distance != null
                                ? widget.pet.formattedDistance
                                : 'Lokalizacja nieznana',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (widget.pet.isUrgent)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.priority_high,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PILNY',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      _showDetailsBottomSheet(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O mnie:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(), // Wyłączamy scrollowanie
                  child: Row(
                    children: _buildPriorityTraits(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPriorityTraits() {
    final traits = <Widget>[];

    // Priorytet 1: Rasa (jeśli dostępna i nie jest null/pusta), w przeciwnym razie wielkość
    if (widget.pet.breed?.isNotEmpty == true && widget.pet.breed != null) {
      traits.add(_buildTraitChip(widget.pet.breed!, Icons.pets));
    } else {
      // Jeśli brak rasy, pokaż wielkość
      traits.add(_buildTraitChip(widget.pet.sizeDisplayName, Icons.height));
    }

    // Priorytet 2: Płeć
    traits.add(_buildTraitChip(widget.pet.genderDisplayName,
        widget.pet.gender == 'male' ? Icons.male : Icons.female));

    return traits;
  }

  Widget _buildTraitChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAge(int age) {
    if (age == 1) {
      return 'rok';
    } else if (age >= 2 && age <= 4) {
      return 'lata';
    } else {
      return 'lat';
    }
  }

  String _formatDisplayAge(int age) {
    if (age == 0) {
      return '<1 rok';
    }
    return '${age} ${_formatAge(age)}';
  }

  Future<void> _contactShelter() async {
    try {
      final conversations = await _messageService.getConversations();
      final existingConversation = conversations
          .where((conv) => conv.petId == widget.pet.id.toString())
          .toList();

      String conversationId;
      bool isNewConversation = false;

      if (existingConversation.isNotEmpty) {
        conversationId = existingConversation.first.id;
      } else {
        conversationId = await _messageService.createConversation(
          petId: widget.pet.id.toString(),
          petName: widget.pet.name,
          shelterId: widget.pet.shelterId.toString(),
          shelterName: widget.pet.shelterName ?? 'Schronisko',
          petImageUrl: widget.pet.imageUrlSafe,
        );
        isNewConversation = true;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatView(
            conversationId: conversationId,
            isNewConversation: isNewConversation,
            pet: widget.pet,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się otworzyć czatu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _getImageWidget(widget.pet.imageUrlSafe, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pet.name,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(widget.pet.breed?.isNotEmpty == true && widget.pet.breed != null) ? widget.pet.breed! : widget.pet.sizeDisplayName}, ${_formatDisplayAge(widget.pet.age)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const Divider(height: 30),

                _buildDetailSection('Opis', widget.pet.description),

                _buildDetailSection('Schronisko', widget.pet.shelterName),

                _buildDetailSection('Adres schroniska', widget.pet.shelterAddress),

                _buildPetTraitsSection(),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _contactShelter();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Skontaktuj się ze schroniskiem',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareProfile();
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Udostępnij profil'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPetTraitsSection() {
    final traits = <Map<String, dynamic>>[];

    // Priorytet 1: Szczepienia i sterylizacja (z kolorami)
    if (widget.pet.isVaccinated) {
      traits.add({'value': 'Zaszczepiony', 'icon': Icons.medical_services, 'color': Colors.green});
    }

    if (widget.pet.isNeutered) {
      traits.add({'value': 'Sterylizowany', 'icon': Icons.healing, 'color': Colors.blue});
    }

    // Reszta traitów (bez labelów, z domyślnym kolorem)
    if (widget.pet.breed?.isNotEmpty == true && widget.pet.breed != null) {
      traits.add({'value': widget.pet.breed!, 'icon': Icons.pets});
    }

    traits.add({'value': widget.pet.genderDisplayName, 'icon': widget.pet.gender == 'male' ? Icons.male : Icons.female});
    traits.add({'value': widget.pet.sizeDisplayName, 'icon': Icons.height});
    traits.add({'value': _formatDisplayAge(widget.pet.age), 'icon': Icons.cake});

    if (widget.pet.isChildFriendly) {
      traits.add({'value': 'Przyjazny dzieciom', 'icon': Icons.child_care});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cechy zwierzaka',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: traits.map((trait) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildInfoTraitChip(trait),
              ),
          ).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }


  Widget _buildInfoTraitChip(Map<String, dynamic> trait) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (trait['color'] as Color? ?? AppColors.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (trait['color'] as Color? ?? AppColors.primaryColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            trait['icon'] as IconData,
            color: trait['color'] as Color? ?? AppColors.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trait['value'] as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: trait['color'] as Color? ?? AppColors.primaryColor,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String? title, String? content) {
    if (title == null || title.isEmpty || content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}