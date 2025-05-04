import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pet_model.dart';
import '../../styles/colors.dart';
import '../../views/chat_view.dart';
import '../../services/message_service.dart';

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

  // Cache dla załadowanych zdjęć
  final Map<String, bool> _loadedImages = {};

  @override
  bool get wantKeepAlive => true; // Zapobiega zniszczeniu stanu widgetu

  @override
  void initState() {
    super.initState();
    // Wstępne załadowanie wszystkich zdjęć
    _preloadImages();
  }

  void _preloadImages() {
    final allImages = _getAllImages();
    for (final imageUrl in allImages) {
      if (!_loadedImages.containsKey(imageUrl)) {
        final imageProvider = NetworkImage(imageUrl);
        imageProvider.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((info, _) {
            if (mounted) {
              setState(() {
                _loadedImages[imageUrl] = true;
              });
            }
          }, onError: (exception, stackTrace) {
            if (mounted) {
              setState(() {
                _loadedImages[imageUrl] = false;
              });
            }
          }),
        );
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
    // Łączymy główne zdjęcie z galerią
    return [widget.pet.imageUrl, ...widget.pet.galleryImages];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wymagane dla AutomaticKeepAliveClientMixin

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
                // Karuzela zdjęć
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPhotoIndex = index;
                    });
                  },
                  itemCount: allImages.length,
                  itemBuilder: (context, index) {
                    final imageUrl = allImages[index];
                    final isLoaded = _loadedImages[imageUrl] ?? false;

                    return Hero(
                      tag: index == 0 ? 'pet_${widget.pet.id}' : 'pet_${widget.pet.id}_$index',
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error_outline, size: 50, color: Colors.grey),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          // Jeśli obraz jest już załadowany w cache, pokaż go natychmiast
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
                        // Dodajemy cache dla zdjęć
                        cacheWidth: MediaQuery.of(context).size.width.round(),
                      ),
                    );
                  },
                ),

                // Przyciski do nawigacji zdjęć
                if (allImages.length > 1) ...[
                  // Przycisk lewo
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _currentPhotoIndex > 0 ? _goToPreviousPhoto : null,
                        child: Container(
                          width: 50,
                          height: double.infinity,
                          color: Colors.transparent,
                          child: _currentPhotoIndex > 0
                              ? Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 30,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Przycisk prawo
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _currentPhotoIndex < allImages.length - 1 ? _goToNextPhoto : null,
                        child: Container(
                          width: 50,
                          height: double.infinity,
                          color: Colors.transparent,
                          child: _currentPhotoIndex < allImages.length - 1
                              ? Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 30,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],

                // Wskaźnik aktualnego zdjęcia - dots
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

                // gradient na dole zdjęcia, by tekst był bardziej czytelny
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
                          image: NetworkImage(widget.pet.imageUrl),
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
                    // TODO: Logika udostępniania
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