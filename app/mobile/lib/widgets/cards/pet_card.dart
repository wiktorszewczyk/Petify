import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pet_model.dart';
import '../../styles/colors.dart';
import '../../views/chat_view.dart';
import '../../services/message_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PetCard extends StatefulWidget {
  final PetModel pet;

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

  final Map<String, bool> _loadedImages = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _preloadImages();
  }

  void _preloadImages() {
    final allImages = _getAllImages();
    for (final imagePath in allImages) {
      if (!_loadedImages.containsKey(imagePath)) {
        if (_isNetworkImage(imagePath)) {
          final imageProvider = NetworkImage(imagePath);
          imageProvider.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener((info, _) {
              if (mounted) {
                setState(() {
                  _loadedImages[imagePath] = true;
                });
              }
            }, onError: (exception, stackTrace) {
              if (mounted) {
                setState(() {
                  _loadedImages[imagePath] = false;
                });
              }
            }),
          );
        } else {
          final imageProvider = AssetImage(imagePath);
          imageProvider.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener((info, _) {
              if (mounted) {
                setState(() {
                  _loadedImages[imagePath] = true;
                });
              }
            }, onError: (exception, stackTrace) {
              if (mounted) {
                setState(() {
                  _loadedImages[imagePath] = false;
                });
              }
            }),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPhoto() {
    if (_currentPhotoIndex < widget.pet.galleryImages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPhoto() {
    if (_currentPhotoIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<String> _getAllImages() {
    return [widget.pet.imageUrl, ...widget.pet.galleryImages];
  }

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _getImageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    final isNetwork = _isNetworkImage(path);
    final isLoaded = _loadedImages[path] ?? false;

    Widget imageWidget;

    if (isNetwork) {
      imageWidget = Image.network(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error_outline, size: 50, color: Colors.grey),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (isLoaded || loadingProgress == null) return child;

          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
              ),
            ),
          );
        },
        cacheWidth: MediaQuery.of(context).size.width.round(),
      );
    } else {
      imageWidget = Image.asset(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error_outline, size: 50, color: Colors.grey),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
              ),
            ),
          );
        },
      );
    }

    return imageWidget;
  }

  void _shareProfile() {
    /// TODO: Generować odpowiedni link do profilu zwierzaka, który można udostepnić
    final placeholderLink = "https://petadopt.example.com/demo/${widget.pet.id}";

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
                Clipboard.setData(ClipboardData(text: placeholderLink));
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
                _shareToSocialMedia('facebook', placeholderLink);
                Navigator.pop(context);
              },
            ),

            _buildShareOption(
              context,
              icon: Icons.camera_alt,
              color: Color(0xFFE1306C),
              title: 'Instagram',
              onTap: () {
                _shareToSocialMedia('instagram', placeholderLink);
                Navigator.pop(context);
              },
            ),

            _buildShareOption(
              context,
              icon: Icons.chat_bubble,
              color: Color(0xFF25D366),
              title: 'WhatsApp',
              onTap: () {
                _shareToSocialMedia('whatsapp', placeholderLink);
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
                  'Poznaj ${widget.pet.name}! ${widget.pet.gender == 'male' ? 'Czeka' : 'Czeka'} '
                      'na adopcję w ${widget.pet.shelterName}. ${placeholderLink}',
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

    /// TODO: Użyć realne API do udostępniania dla każdej platformy
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

    final allImages = _getAllImages();

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
                // Karuzela zdjęć z wyłączonym przewijaniem przy przeciąganiu
                PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // To wyłącza przewijanie przez użytkownika
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

                if (allImages.length > 1) ...[
                  // Przycisk do przewijania w lewo - na całej lewej stronie zdjęcia
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

                  // Przycisk do przewijania w prawo - na całej prawej stronie zdjęcia
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
                          Text(
                            widget.pet.name,
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.pet.age} ${_formatAge(widget.pet.age)}',
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
                            'Odległość: ${widget.pet.distance} km',
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
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTraitChip(widget.pet.breed, Icons.pets),
                      _buildTraitChip(widget.pet.gender == 'male' ? 'Samiec' : 'Samica',
                          widget.pet.gender == 'male' ? Icons.male : Icons.female),
                      _buildTraitChip(_getSizeText(widget.pet.size), Icons.height),
                      if (widget.pet.isChildFriendly)
                        _buildTraitChip('Przyjazny dzieciom', Icons.child_care),
                      if (widget.pet.isNeutered)
                        _buildTraitChip('Sterylizowany', Icons.healing),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _getSizeText(String size) {
    switch (size.toLowerCase()) {
      case 'small':
        return 'Mały';
      case 'medium':
        return 'Średni';
      case 'large':
        return 'Duży';
      case 'xlarge':
        return 'Bardzo duży';
      default:
        return size;
    }
  }

  Future<void> _contactShelter() async {
    try {
      final conversations = await _messageService.getConversations();
      final existingConversation = conversations
          .where((conv) => conv.petId == widget.pet.id)
          .toList();

      String conversationId;
      bool isNewConversation = false;

      if (existingConversation.isNotEmpty) {
        conversationId = existingConversation.first.id;
      } else {
        conversationId = await _messageService.createConversation(
          petId: widget.pet.id,
          petName: widget.pet.name,
          shelterId: widget.pet.shelterId,
          shelterName: widget.pet.shelterName ?? 'Schronisko',
          petImageUrl: widget.pet.imageUrl,
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
                        image: DecorationImage(
                          image: _isNetworkImage(widget.pet.imageUrl)
                              ? NetworkImage(widget.pet.imageUrl) as ImageProvider
                              : AssetImage(widget.pet.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
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
                          '${widget.pet.breed}, ${widget.pet.age} ${_formatAge(widget.pet.age)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const Divider(height: 30),

                _buildDetailSection('Opis', widget.pet.description),

                _buildDetailSection('Schronisko', widget.pet.shelterName),

                _buildDetailSection('Adres', widget.pet.shelterAddress),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
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

  Widget _buildDetailSection(String title, String content) {
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