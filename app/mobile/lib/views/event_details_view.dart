import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';
import '../models/event.dart';
import '../models/donation.dart';
import '../models/shelter.dart';
import '../services/feed_service.dart';
import '../services/shelter_service.dart';
import '../services/user_service.dart';
import '../services/payment_service.dart';
import '../services/cache/cache_manager.dart';
import '../models/event_participant.dart';
import '../styles/colors.dart';
import 'payment_view.dart';

class EventDetailsView extends StatefulWidget {
  final Event event;
  const EventDetailsView({super.key, required this.event});

  @override
  State<EventDetailsView> createState() => _EventDetailsViewState();
}

class _EventDetailsViewState extends State<EventDetailsView> {
  final _feedService = FeedService();
  final _shelterService = ShelterService();
  final _paymentService = PaymentService();
  int? _participants;
  String? _shelterName;
  Shelter? _shelter;
  FundraiserResponse? _fundraiser;
  bool _joining = false;
  bool _joined = false;
  bool _isLoadingFundraiser = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _participants = widget.event.participantsCount;
    _loadAdditionalData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAdditionalData() async {
    await Future.wait([
      _loadParticipantsAndStatus(),
      _loadShelter(),
      _loadFundraiserInfo(),
    ]);
  }

  Future<void> _loadParticipantsAndStatus() async {
    try {
      final participants = await _feedService.getEventParticipants(int.parse(widget.event.id));
      final user = await UserService().getCurrentUser();
      setState(() {
        _participants = participants.length;
        _joined = participants.any((p) => p.username == user.username);
      });
    } catch (_) {
      try {
        final count = await _feedService.getEventParticipantsCount(int.parse(widget.event.id));
        setState(() {
          _participants = count;
        });
      } catch (_) {}
    }
  }

  Future<void> _loadShelter() async {
    if (widget.event.shelterId == null) return;
    try {
      final shelter = await _shelterService.getShelterById(widget.event.shelterId!);
      setState(() {
        _shelter = shelter;
        _shelterName = shelter.name;
      });
    } catch (_) {}
  }

  Future<void> _loadFundraiserInfo() async {
    if (widget.event.fundraisingId == null) return;

    setState(() {
      _isLoadingFundraiser = true;
    });

    try {
      final fundraiser = await _paymentService.getFundraiser(widget.event.fundraisingId!);
      setState(() {
        _fundraiser = fundraiser;
        _isLoadingFundraiser = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFundraiser = false;
      });
      print('❌ EventDetailsView: Błąd podczas ładowania danych zbiórki: $e');
    }
  }

  Future<void> _joinEvent() async {
    setState(() {
      _joining = true;
    });
    try {
      await _feedService.joinEvent(int.parse(widget.event.id));

      CacheManager.invalidatePattern('events_');
      CacheManager.invalidatePattern('feed_');
      CacheManager.invalidatePattern('user_');
      print('🗑️ EventDetailsView: Invalidated cache after joining event ${widget.event.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event.requiresRegistration
                ? 'Zarejestrowano na wydarzenie'
                : 'Dołączono do wydarzenia'),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() {
        _joined = true;
        if (_participants != null) {
          _participants = _participants! + 1;
        }
      });
    } catch (e) {
      if (e.toString().contains('Już bierzesz udział')) {
        setState(() {
          _joined = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _joining = false;
      });
    }
  }

  void _donateToFundraiser() async {
    if (_fundraiser == null || widget.event.shelterId == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentView(
          shelterId: widget.event.shelterId!,
          shelter: _shelter,
          fundraiserId: _fundraiser!.id,
          initialAmount: 20.0,
          title: 'Wspieraj: ${_fundraiser!.title}',
          description: _fundraiser!.description,
        ),
      ),
    );

    if (result == true && mounted) {
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

  String _formatEventDate(DateTime date, DateTime? endDate) {
    final formatter = DateFormat('dd.MM.yyyy');
    final timeFormatter = DateFormat('HH:mm');

    String formattedDate = formatter.format(date);
    String formattedTime = timeFormatter.format(date);

    if (endDate != null) {
      if (formatter.format(date) == formatter.format(endDate)) {
        return '$formattedDate, $formattedTime - ${timeFormatter.format(endDate)}';
      } else {
        return '$formattedDate $formattedTime - ${formatter.format(endDate)} ${timeFormatter.format(endDate)}';
      }
    }
    return '$formattedDate, $formattedTime';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final bool unlimited = event.capacity == null || event.capacity! <= 0;
    final String? participantsCountText =
    _participants != null ? 'Liczba uczestników: $_participants' : null;
    final String? seatsText = unlimited
        ? 'Brak limitu miejsc'
        : (_participants != null
        ? 'Wolne miejsca: ${event.capacity! - _participants!.clamp(0, event.capacity!)}'
        : null);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              'Wydarzenie',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: event.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            color: Colors.white,
                            child: Center(
                              child: Icon(Icons.event, size: 50, color: Colors.grey[400]),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                          ),
                        ),
                        fadeInDuration: const Duration(milliseconds: 300),
                        fadeOutDuration: const Duration(milliseconds: 100),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                      if (event.eventType != null)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getEventTypeColor(event.eventType!),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event.eventType!,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Text(
                          event.title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.home_work_outlined, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _shelterName ?? event.organizerName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month, size: 24, color: AppColors.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatEventDate(event.date, event.endDate),
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  if (_isToday(event.date) || _isTomorrow(event.date)) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _isToday(event.date) ? 'Dzisiaj!' : 'Jutro!',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.red[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 24, color: AppColors.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.location,
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Otwieranie mapy...')),
                                      );
                                    },
                                    child: Text(
                                      'Pokaż na mapie',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_fundraiser != null) ...[
                        _buildFundraiserCard(),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'O wydarzeniu',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      if (participantsCountText != null) ...[
                        Row(
                          children: [
                            Icon(Icons.people, size: 18, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Text(
                              participantsCountText,
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (seatsText != null) ...[
                        Row(
                          children: [
                            Icon(Icons.event_available, size: 18, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Text(
                              seatsText,
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _joined || _joining ? null : () {
                            HapticFeedback.mediumImpact();
                            _joinEvent();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _joining
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Text(
                            _joined
                                ? ((event.capacity != null && event.capacity! > 0) ? 'Zarejestrowano' : 'Zadeklarowano udział')
                                : ((event.capacity != null && event.capacity! > 0) ? 'Zarejestruj się' : 'Zadeklaruj udział'),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Udostępnianie wydarzenia...')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share, size: 18, color: AppColors.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Udostępnij',
                                style: GoogleFonts.poppins(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Konfetti overlay
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
              onPressed: () {
                HapticFeedback.mediumImpact();
                _donateToFundraiser();
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

  Color _getEventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'dzień otwarty':
        return Colors.blue;
      case 'spacer':
        return Colors.green;
      case 'warsztaty':
        return Colors.purple;
      case 'szkolenie':
        return Colors.teal;
      case 'festyn':
        return Colors.pink;
      default:
        return Colors.blueGrey;
    }
  }
}