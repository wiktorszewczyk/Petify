import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/feed_service.dart';
import '../services/shelter_service.dart';
import '../services/user_service.dart';
import '../models/event_participant.dart';
import '../styles/colors.dart';

class EventDetailsView extends StatefulWidget {
  final Event event;
  const EventDetailsView({super.key, required this.event});

  @override
  State<EventDetailsView> createState() => _EventDetailsViewState();
}

class _EventDetailsViewState extends State<EventDetailsView> {
  final _feedService = FeedService();
  final _shelterService = ShelterService();
  int? _participants;
  String? _shelterName;
  bool _joining = false;
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _participants = widget.event.participantsCount;
    _loadAdditionalData();
  }

  Future<void> _loadAdditionalData() async {
    await Future.wait([
      _loadParticipantsAndStatus(),
      _loadShelter(),
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
        _shelterName = shelter.name;
      });
    } catch (_) {}
  }

  Future<void> _joinEvent() async {
    setState(() {
      _joining = true;
    });
    try {
      await _feedService.joinEvent(int.parse(widget.event.id));
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

    return Scaffold(
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
                  Image.network(event.imageUrl, fit: BoxFit.cover),
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
                      onPressed: _joined || _joining ? null : _joinEvent,
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
                            ? 'Zarejestrowano'
                            : (event.requiresRegistration ? 'Zarejestruj się' : 'Dołącz do wydarzenia'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
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