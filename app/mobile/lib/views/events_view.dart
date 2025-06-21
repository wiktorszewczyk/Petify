import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/event.dart';
import '../models/donation.dart';
import '../services/feed_service.dart';
import '../services/payment_service.dart';
import '../styles/colors.dart';
import "event_details_view.dart";
import '../services/shelter_service.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  bool _isLoading = false;
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  Map<int, FundraiserResponse?> _eventFundraisers = {};
  String _selectedFilter = 'Wszystkie';
  final List<String> _filters = ['Wszystkie', 'Dzisiaj', 'W tym tygodniu', 'W tym miesiącu'];
  final TextEditingController _searchController = TextEditingController();
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  DateTime _getStartOfWeek(DateTime date) {
    return _getStartOfDay(date.subtract(Duration(days: date.weekday - 1)));
  }

  DateTime _getEndOfWeek(DateTime date) {
    return _getEndOfDay(date.add(Duration(days: 7 - date.weekday)));
  }

  DateTime _getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _getEndOfMonth(DateTime date) {
    return _getEndOfDay(DateTime(date.year, date.month + 1, 0));
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final feedService = FeedService();
      final shelterService = ShelterService();
      final events = await feedService.getIncomingEvents(60);

      final enriched = await Future.wait(events.map((e) async {
        int? count;
        try {
          count = await feedService.getEventParticipantsCount(int.parse(e.id));
        } catch (_) {}

        String organizer = e.organizerName;
        if (e.shelterId != null) {
          try {
            final shelter = await shelterService.getShelterById(e.shelterId!);
            organizer = shelter.name;
          } catch (_) {}
        }

        return e.copyWith(
          organizerName: organizer,
          participantsCount: count,
        );
      }).toList());

      final fundraisers = <int, FundraiserResponse?>{};
      for (final event in enriched) {
        if (event.fundraisingId != null) {
          try {
            final fundraiser = await _paymentService.getFundraiser(event.fundraisingId!);
            fundraisers[event.fundraisingId!] = fundraiser;
          } catch (e) {
            fundraisers[event.fundraisingId!] = null;
          }
        }
      }

      setState(() {
        _events = enriched;
        _eventFundraisers = fundraisers;
        _filterEvents();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się pobrać wydarzeń: $e')),
        );
      }
    }
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    final now = DateTime.now();

    setState(() {
      if (_selectedFilter == 'Wszystkie') {
        _filteredEvents = _events.where((event) {
          return event.title.toLowerCase().contains(query) ||
              event.organizerName.toLowerCase().contains(query) ||
              event.description.toLowerCase().contains(query) ||
              event.location.toLowerCase().contains(query) ||
              (event.eventType != null && event.eventType!.toLowerCase().contains(query));
        }).toList();
      } else if (_selectedFilter == 'Dzisiaj') {
        final startOfDay = _getStartOfDay(now);
        final endOfDay = _getEndOfDay(now);

        _filteredEvents = _events.where((event) {
          return event.date.isAfter(startOfDay) &&
              event.date.isBefore(endOfDay) &&
              (event.title.toLowerCase().contains(query) ||
                  event.organizerName.toLowerCase().contains(query) ||
                  event.description.toLowerCase().contains(query) ||
                  event.location.toLowerCase().contains(query) ||
                  (event.eventType != null && event.eventType!.toLowerCase().contains(query)));
        }).toList();
      } else if (_selectedFilter == 'W tym tygodniu') {
        final startOfWeek = _getStartOfWeek(now);
        final endOfWeek = _getEndOfWeek(now);

        _filteredEvents = _events.where((event) {
          return event.date.isAfter(startOfWeek) &&
              event.date.isBefore(endOfWeek) &&
              (event.title.toLowerCase().contains(query) ||
                  event.organizerName.toLowerCase().contains(query) ||
                  event.description.toLowerCase().contains(query) ||
                  event.location.toLowerCase().contains(query) ||
                  (event.eventType != null && event.eventType!.toLowerCase().contains(query)));
        }).toList();
      } else if (_selectedFilter == 'W tym miesiącu') {
        final startOfMonth = _getStartOfMonth(now);
        final endOfMonth = _getEndOfMonth(now);

        _filteredEvents = _events.where((event) {
          return event.date.isAfter(startOfMonth) &&
              event.date.isBefore(endOfMonth) &&
              (event.title.toLowerCase().contains(query) ||
                  event.organizerName.toLowerCase().contains(query) ||
                  event.description.toLowerCase().contains(query) ||
                  event.location.toLowerCase().contains(query) ||
                  (event.eventType != null && event.eventType!.toLowerCase().contains(query)));
        }).toList();
      }

      _filteredEvents.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  void _showEventDetails(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsView(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wydarzenia',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        color: AppColors.primaryColor,
        child: Column(
          children: [
            _buildSearchAndFilterBar(),
            Expanded(
              child: _isLoading ? _buildLoadingIndicator() : _buildEventsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Szukaj wydarzeń...',
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
              ),
            ),
            onChanged: (value) {
              _filterEvents();
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.black : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                        _filterEvents();
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: AppColors.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryColor : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 20, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 16, width: 200, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 150, color: Colors.white),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(height: 14, width: 100, color: Colors.white),
                          const SizedBox(width: 16),
                          Container(height: 14, width: 80, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsList() {
    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Brak wydarzeń',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter != 'Wszystkie'
                  ? 'Zmień filtry, aby zobaczyć więcej wydarzeń'
                  : 'Obecnie nie ma żadnych zaplanowanych wydarzeń',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredEvents.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];

        final bool showDateHeader = index == 0 ||
            !_isSameDay(_filteredEvents[index - 1].date, event.date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader) ...[
              if (index > 0) const SizedBox(height: 16),
              _buildDateHeader(event.date),
              const SizedBox(height: 8),
            ],
            _buildEventCard(event),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    String headerText;

    if (_isSameDay(date, now)) {
      headerText = 'Dzisiaj';
    } else if (_isSameDay(date, tomorrow)) {
      headerText = 'Jutro';
    } else {
      final formatter = DateFormat('EEEE, d MMMM', 'pl_PL');
      headerText = formatter.format(date);
      headerText = headerText[0].toUpperCase() + headerText.substring(1);
    }

    return Text(
      headerText,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final fundraiser = event.fundraisingId != null ? _eventFundraisers[event.fundraisingId!] : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showEventDetails(event);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          color: Colors.white,
                          child: Center(
                            child: Icon(Icons.event, size: 40, color: Colors.grey[400]),
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
                  ),
                ),
                if (event.eventType != null)
                  Positioned(
                    top: 12,
                    left: 12,
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
                if (event.requiresRegistration)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rejestracja',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('HH:mm').format(event.date),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (event.endDate != null) ...[
                        Text(
                          ' - ${DateFormat('HH:mm').format(event.endDate!)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.home_work_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.organizerName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (fundraiser != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
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
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Trwa zbiórka pieniędzy',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
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
                                'Zebrano: ${fundraiser.currentAmount.toInt()} PLN',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Cel: ${fundraiser.goalAmount.toInt()} PLN',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: fundraiser.progressPercentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${fundraiser.progressPercentage.toInt()}% celu',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (event.participantsCount != null) ...[
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${event.participantsCount} ${event.participantsCount == 1 ? 'uczestnik' : (event.participantsCount! < 5 ? 'uczestników' : 'uczestników')}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
      begin: 0.2,
      end: 0,
      duration: 300.ms,
      curve: Curves.easeOutCubic,
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