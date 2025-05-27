import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/support_options_sheet.dart';
import '../models/pet.dart';
import '../styles/colors.dart';
import '../services/pet_service.dart';
import '../services/message_service.dart';
import 'chat_view.dart';

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

  @override
  void initState() {
    super.initState();
    _petService = PetService();
    _messageService = MessageService();
  }

  List<String> get _allImages => [widget.pet.imageUrl, ...widget.pet.galleryImages];

  String _y(int n) => n == 1 ? 'rok' : (n >= 2 && n <= 4 ? 'lata' : 'lat');

  String _size(String s) => {
    'small': 'Mały',
    'medium': 'Średni',
    'large': 'Duży',
    'xlarge': 'B.duży'
  }[s.toLowerCase()] ??
      s;

  List<String> get _traits {
    final t = <String>[widget.pet.gender == 'male' ? 'Samiec' : 'Samica', _size(widget.pet.size)];
    if (widget.pet.isVaccinated) t.add('Zaszczepiony');
    if (widget.pet.isNeutered) t.add('Sterylizowany');
    if (widget.pet.isChildFriendly) t.add('Przyjazny dzieciom');
    return t;
  }

  ButtonStyle _btnStyle(
      Color bg,
      Color fg, {
        double elevation = 0,
        Color? borderColor,
      }) =>
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

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: fit);
    } else {
      return Image.asset(path, fit: fit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelterName = widget.pet.shelterName?.isNotEmpty == true ? widget.pet.shelterName! : 'Schronisko';
    final shelterAddr = widget.pet.shelterAddress?.isNotEmpty == true ? widget.pet.shelterAddress! : 'brak adresu';

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
                        tag: 'pet_mini_${widget.pet.id}',
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
                        child: Text(widget.pet.name, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primaryColor.withOpacity(.2), borderRadius: BorderRadius.circular(12)),
                        child: Text('${widget.pet.age} ${_y(widget.pet.age)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  _iconText(Icons.pets, widget.pet.breed),
                  const SizedBox(height: 6),
                  _iconText(Icons.location_on, 'Odległość: ${widget.pet.distance} km'),

                  if (widget.pet.isUrgent) ...[
                    const SizedBox(height: 16),
                    _urgent(),
                  ],

                  const SizedBox(height: 24),
                  _section('O zwierzaku'),
                  Text(
                    widget.pet.description ?? 'Brak opisu. Skontaktuj się ze schroniskiem, aby dowiedzieć się więcej.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  if (_traits.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _section('Cechy'),
                    Wrap(spacing: 8, runSpacing: 8, children: _traits.map(_chip).toList(growable: false)),
                  ],

                  const SizedBox(height: 24),
                  _section('Schronisko'),
                  const SizedBox(height: 8),
                  _shelterBox(shelterName, shelterAddr),

                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Usuń z polubionych', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
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
                        Text('ADOPTUJ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      builder: (context) => SupportOptionsSheet(pet: widget.pet),
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

  Widget _circle(Widget child) => Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(.8), shape: BoxShape.circle), child: child);

  Widget _iconText(IconData icon, String text) => Row(children: [Icon(icon, size: 20, color: Colors.grey[600]), const SizedBox(width: 6), Text(text)]);

  Widget _section(String t) => Text(t, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold));

  Widget _chip(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.primaryColor.withOpacity(.1), borderRadius: BorderRadius.circular(20)), child: Text(t, style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w500)));

  Widget _urgent() => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.red.withOpacity(.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)), child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18), SizedBox(width: 6), Text('PILNY', style: TextStyle(color: Colors.red))]));

  Widget _shelterBox(String name, String addr) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: Row(children: [Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryColor), child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 30)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(addr, style: TextStyle(color: Colors.grey[600]))]))]));

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

  Future<void> _contactShelter() async {
    setState(() => _busy = true);

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

      setState(() => _busy = false);

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

  Future<void> _openAdoptionForm() async => _soon('Formularz adopcji');

  void _soon(String w) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$w – wkrótce'), backgroundColor: Colors.blue));

  Future<void> _confirmRemove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usuń z ulubionych'),
        content: Text('Na pewno chcesz usunąć ${widget.pet.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usuń', style: TextStyle(color: Colors.red)))
        ],
      ),
    ) ??
        false;

    if (!ok) return;

    setState(() => _busy = true);
    try {
      await _petService.unlikePet(widget.pet.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.pet.name} usunięty z ulubionych'), backgroundColor: Colors.grey));
    } catch (e) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}