import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/support_options_sheet.dart';
import 'package:mobile/views/adoption_form_view.dart';
import '../models/pet.dart';
import '../styles/colors.dart';
import '../services/pet_service.dart';
import '../services/message_service.dart';
import 'chat_view.dart';

class TraitItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  TraitItem(this.label, this.value, this.icon, {this.color});
}

class PetDetailsView extends StatefulWidget {
  final Pet pet;
  const PetDetailsView({Key? key, required this.pet}) : super(key: key);

  @override
  State<PetDetailsView> createState() => _PetDetailsViewState();
}

class _PetDetailsViewState extends State<PetDetailsView> {
  late final PetService _petService;
  late final MessageService _messageService;
  final PageController _pageController = PageController();
  int _currentPhoto = 0;
  bool _busy = false;
  Pet? _refreshedPet;

  @override
  void initState() {
    super.initState();
    _petService = PetService();
    _messageService = MessageService();
    if (widget.pet.distance == null) {
      _loadPetDetails();
    }
  }

  Future<void> _loadPetDetails() async {
    try {
      final refreshedPet = await _petService.getPetById(widget.pet.id);
      if (mounted) {
        setState(() {
          _refreshedPet = refreshedPet;
        });
      }
    } catch (e) {
      print('Failed to refresh pet details: $e');
    }
  }

  Pet get currentPet => _refreshedPet ?? widget.pet;

  List<String> get _allImages {
    return [currentPet.imageUrlSafe, ...currentPet.galleryImages];
  }

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildErrorImage(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
              ),
            ),
          );
        },
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildErrorImage(),
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

  @override
  Widget build(BuildContext context) {
    final shelterName = currentPet.shelterName?.isNotEmpty == true
        ? currentPet.shelterName!
        : 'Schronisko';
    final shelterAddr = currentPet.shelterAddress?.isNotEmpty == true
        ? currentPet.shelterAddress!
        : 'brak adresu';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.primaryColor,
            expandedHeight: 350,
            pinned: true,
            leading: IconButton(
              icon: _circle(const Icon(Icons.arrow_back, color: Colors.black)),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPhoto = i),
                    itemCount: _allImages.length,
                    itemBuilder: (_, i) => i == 0
                        ? Hero(
                        tag: 'pet_mini_${currentPet.id}',
                        child: _buildImage(_allImages[i])
                    )
                        : _buildImage(_allImages[i]),
                  ),

                  if (_allImages.length > 1) _navArrow(left: true, enabled: _currentPhoto > 0),
                  if (_allImages.length > 1) _navArrow(left: false, enabled: _currentPhoto < _allImages.length - 1),

                  if (_allImages.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _allImages.length,
                              (i) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPhoto == i ? AppColors.primaryColor : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            currentPet.name,
                            style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold
                            )
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(.2),
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: Text(
                            '${currentPet.age} ${_y(currentPet.age)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor
                            )
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  _iconText(Icons.pets, currentPet.breed ?? currentPet.typeDisplayName),
                  const SizedBox(height: 6),
                  _iconText(
                      Icons.location_on,
                      currentPet.distance != null
                          ? 'Odległość: ${currentPet.formattedDistance}'
                          : 'Lokalizacja nieznana'
                  ),

                  if (currentPet.isUrgent) ...[
                    const SizedBox(height: 16),
                    _urgent(),
                  ],

                  const SizedBox(height: 24),
                  _section('O zwierzaku'),
                  Text(
                    currentPet.description ?? 'Brak opisu. Skontaktuj się ze schroniskiem, aby dowiedzieć się więcej.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  if (_allTraits.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _section('Cechy zwierzaka'),
                    _buildTraitsGrid(),
                  ],

                  const SizedBox(height: 24),
                  _section('Schronisko'),
                  const SizedBox(height: 8),
                  _shelterBox(shelterName, shelterAddr),

                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                          'Usuń z polubionych',
                          style: TextStyle(color: Colors.red)
                      ),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                      ),
                      onPressed: _confirmRemove,
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _contactShelter,
                    style: _btnStyle(
                      Colors.white,
                      Colors.black87,
                      elevation: 2,
                      borderColor: Colors.grey.shade300,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.message_outlined, size: 22),
                        SizedBox(height: 4),
                        Text('Kontakt', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _openAdoptionForm,
                    style: _btnStyle(
                      AppColors.primaryColor,
                      Colors.white,
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.pets, size: 20),
                        SizedBox(width: 8),
                        Text(
                            'ADOPTUJ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SupportOptionsSheet(pet: currentPet),
                    ),
                    style: _btnStyle(
                      Colors.white,
                      Colors.blue,
                      elevation: 2,
                      borderColor: Colors.blue.shade200,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.volunteer_activism, size: 22),
                        SizedBox(height: 4),
                        Text('Wesprzyj', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circle(Widget child) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(.8),
          shape: BoxShape.circle
      ),
      child: child
  );

  Widget _iconText(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(text)
      ]
  );

  Widget _section(String t) => Text(
      t,
      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)
  );

  Widget _chip(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(.1),
          borderRadius: BorderRadius.circular(20)
      ),
      child: Text(
          t,
          style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500
          )
      )
  );

  Widget _urgent() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.red.withOpacity(.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red)
      ),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
            SizedBox(width: 6),
            Text('PILNY', style: TextStyle(color: Colors.red))
          ]
      )
  );

  Widget _shelterBox(String name, String addr) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12)
      ),
      child: Row(
          children: [
            Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor
                ),
                child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 30)
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          name,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 4),
                      if (addr.isNotEmpty)
                        Text(addr, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      if (currentPet.shelterName?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Kliknij "Skontaktuj się" aby uzyskać więcej informacji',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ]
                    ]
                )
            )
          ]
      )
  );

  Widget _navArrow({required bool left, required bool enabled}) => Positioned.fill(
    child: Align(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: GestureDetector(
        onTap: enabled
            ? () {
          left
              ? _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
              : _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
            : null,
        child: Container(
          width: 60,
          color: Colors.transparent,
          child: enabled
              ? Container(
            margin: EdgeInsets.only(left: left ? 8 : 0, right: left ? 0 : 8),
            decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
            padding: const EdgeInsets.all(8),
            child: Icon(left ? Icons.chevron_left : Icons.chevron_right, color: Colors.white, size: 30),
          )
              : null,
        ),
      ),
    ),
  );

  ButtonStyle _btnStyle(Color bg, Color fg, {double elevation = 0, Color? borderColor}) =>
      ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: elevation,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
        ),
      );

  String _y(int n) => n == 1 ? 'rok' : (n >= 2 && n <= 4 ? 'lata' : 'lat');

  List<String> get _traits {
    final t = <String>[
      currentPet.genderDisplayName,
      currentPet.sizeDisplayName
    ];
    if (currentPet.isVaccinated) t.add('Zaszczepiony');
    if (currentPet.isNeutered) t.add('Sterylizowany');
    if (currentPet.isChildFriendly) t.add('Przyjazny dzieciom');
    return t;
  }

  List<TraitItem> get _allTraits {
    final traits = <TraitItem>[];

    if (currentPet.isVaccinated) {
      traits.add(TraitItem('', 'Zaszczepiony', Icons.medical_services, color: Colors.green));
    }

    if (currentPet.isNeutered) {
      traits.add(TraitItem('', 'Sterylizowany', Icons.healing, color: Colors.blue));
    }

    if (currentPet.breed?.isNotEmpty == true) {
      traits.add(TraitItem('', currentPet.breed!, Icons.pets));
    }

    traits.add(TraitItem('', currentPet.genderDisplayName, currentPet.gender == 'male' ? Icons.male : Icons.female));
    traits.add(TraitItem('', currentPet.sizeDisplayName, Icons.height));
    traits.add(TraitItem('', '${currentPet.age} ${_y(currentPet.age)}', Icons.cake));

    if (currentPet.isChildFriendly) {
      traits.add(TraitItem('', 'Przyjazny dzieciom', Icons.child_care));
    }

    return traits;
  }

  Widget _buildTraitsGrid() {
    final traits = _allTraits;
    return Column(
      children: traits.map((trait) =>
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildTraitChip(trait),
          ),
      ).toList(),
    );
  }

  Widget _buildTraitChip(TraitItem trait) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (trait.color ?? AppColors.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (trait.color ?? AppColors.primaryColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            trait.icon,
            color: trait.color ?? AppColors.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trait.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: trait.color ?? AppColors.primaryColor,
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

  Future<void> _contactShelter() async {
    setState(() => _busy = true);

    try {
      final conversations = await _messageService.getConversations();
      final existingConversation = conversations
          .where((conv) => conv.petId == currentPet.id.toString())
          .toList();

      String conversationId;
      bool isNewConversation = false;

      if (existingConversation.isNotEmpty) {
        conversationId = existingConversation.first.id;
      } else {
        conversationId = await _messageService.createConversation(
          petId: currentPet.id.toString(),
          petName: currentPet.name,
          shelterId: currentPet.shelterId.toString(),
          shelterName: currentPet.shelterName ?? 'Schronisko',
          petImageUrl: currentPet.imageUrl!,
        );
        isNewConversation = true;
      }

      if (!mounted) return;

      setState(() => _busy = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatView(
            conversationId: conversationId,
            isNewConversation: isNewConversation,
            pet: currentPet,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się otworzyć czatu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAdoptionForm() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdoptionFormView(pet: currentPet),
      ),
    );
  }


  Future<void> _confirmRemove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usuń z ulubionych'),
        content: Text('Na pewno chcesz usunąć ${currentPet.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj')
          ),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Usuń', style: TextStyle(color: Colors.red))
          )
        ],
      ),
    ) ?? false;

    if (!ok) return;

    setState(() => _busy = true);
    try {
      final response = await _petService.unlikePet(currentPet.id);
      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${currentPet.name} usunięty z ulubionych'),
                backgroundColor: Colors.grey
            )
        );
      } else {
        throw Exception('Błąd serwera: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}