import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../styles/colors.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  bool _isLoading = false;
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  String _selectedFilter = 'Wszystkie';
  final List<String> _filters = ['Wszystkie', 'Dzisiaj', 'W tym tygodniu', 'W tym miesiącu'];
  final TextEditingController _searchController = TextEditingController();

  // Obrazy placeholder dla wydarzeń
  final List<String> _placeholderImages = [
    'https://images.pexels.com/photos/1633522/pexels-photo-1633522.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // dzień otwarty
    'https://images.pexels.com/photos/1254140/pexels-photo-1254140.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // spacer z psem
    'https://images.pexels.com/photos/1906153/pexels-photo-1906153.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // wolontariat
    'https://images.pexels.com/photos/8434641/pexels-photo-8434641.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // warsztaty
    'https://images.pexels.com/photos/7707027/pexels-photo-7707027.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // festyn
    'https://images.pexels.com/photos/6646918/pexels-photo-6646918.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // szkolenie
  ];

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
    // Początek tygodnia (poniedziałek)
    return _getStartOfDay(date.subtract(Duration(days: date.weekday - 1)));
  }

  DateTime _getEndOfWeek(DateTime date) {
    // Koniec tygodnia (niedziela)
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
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final tomorrow = today.add(const Duration(days: 1));
      final dayAfterTomorrow = today.add(const Duration(days: 2));
      final nextWeek = today.add(const Duration(days: 7));
      final twoWeeksLater = today.add(const Duration(days: 14));
      final nextMonth = today.add(const Duration(days: 30));

      final events = [
        Event(
          id: '1',
          title: 'Dzień otwarty w schronisku',
          organizerName: 'Schronisko dla zwierząt "Azyl"',
          description: 'Zapraszamy wszystkich na dzień otwarty w naszym schronisku! Poznaj naszych podopiecznych i dowiedz się jak pomóc. W programie: zwiedzanie schroniska, prezentacja podopiecznych, konsultacje z behawiorystą.',
          imageUrl: _placeholderImages[0],
          date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0), // 10:00
          endDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 16, 0), // 16:00
          location: 'Kraków, ul. Adopcyjna 12',
          eventType: 'Dzień otwarty',
          participantsCount: 35,
        ),
        Event(
          id: '2',
          title: 'Spacer z psami ze schroniska',
          organizerName: 'Miejskie Schronisko dla Zwierząt',
          description: 'Zapraszamy wszystkich miłośników psów na sobotnie spacery z naszymi podopiecznymi. To dla nich szansa na chwilę normalności i radości poza boksem.',
          imageUrl: _placeholderImages[1],
          date: DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 10, 30), // 10:30
          endDate: DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 13, 0), // 13:00
          location: 'Łódź, ul. Schroniskowa 45',
          eventType: 'Spacer',
          participantsCount: 18,
          requiresRegistration: true,
        ),
        Event(
          id: '3',
          title: 'Warsztaty dla wolontariuszy',
          organizerName: 'Fundacja "Cztery Łapy"',
          description: 'Organizujemy szkolenie dla osób chcących zostać wolontariuszami w naszym schronisku. W programie: podstawy opieki nad zwierzętami, pierwsza pomoc, techniki pracy z psami lękliwymi.',
          imageUrl: _placeholderImages[2],
          date: DateTime(nextWeek.year, nextWeek.month, nextWeek.day + 3, 17, 0), // 17:00, 3 dni po następnym tygodniu
          endDate: DateTime(nextWeek.year, nextWeek.month, nextWeek.day + 3, 20, 0), // 20:00
          location: 'Poznań, ul. Wolontariacka 8',
          eventType: 'Warsztaty',
          participantsCount: 15,
          requiresRegistration: true,
        ),
        Event(
          id: '4',
          title: 'Festyn charytatywny "Pomóż Zwierzakom"',
          organizerName: 'Fundacja "Łapa w Łapę"',
          description: 'Wielki festyn charytatywny na rzecz zwierząt w schroniskach. W programie: licytacje, koncerty, atrakcje dla dzieci, stoiska z rękodziełem, loteria fantowa. Cały dochód zostanie przeznaczony na leczenie i rehabilitację zwierząt.',
          imageUrl: _placeholderImages[4],
          date: DateTime(nextMonth.year, nextMonth.month, nextMonth.day - 5, 12, 0), // 12:00, 5 dni przed następnym miesiącem
          endDate: DateTime(nextMonth.year, nextMonth.month, nextMonth.day - 5, 20, 0), // 20:00
          location: 'Warszawa, Park Miejski',
          eventType: 'Festyn',
          participantsCount: 120,
        ),
        Event(
          id: '5',
          title: 'Szkolenie z behawiorystą',
          organizerName: 'Schronisko "Psia Łapka"',
          description: 'Zapraszamy na szkolenie z behawiorystą, który opowie o podstawach pracy z psami problemowymi. Dowiesz się, jak pomóc psom lękliwym i reagującym agresywnie.',
          imageUrl: _placeholderImages[5],
          date: DateTime(twoWeeksLater.year, twoWeeksLater.month, twoWeeksLater.day, 18, 0), // 18:00
          endDate: DateTime(twoWeeksLater.year, twoWeeksLater.month, twoWeeksLater.day, 20, 30), // 20:30
          location: 'Warszawa, ul. Zwierzyniecka 5',
          eventType: 'Szkolenie',
          participantsCount: 25,
          requiresRegistration: true,
        ),
        Event(
          id: '6',
          title: 'Warsztaty fotografii zwierząt',
          organizerName: 'Kocia Przystań',
          description: 'Warsztaty fotograficzne, podczas których nauczysz się jak robić atrakcyjne zdjęcia zwierzętom w schronisku. Dobre zdjęcia zwiększają szanse na adopcję!',
          imageUrl: _placeholderImages[3],
          date: DateTime(dayAfterTomorrow.year, dayAfterTomorrow.month, dayAfterTomorrow.day, 16, 30), // 16:30, 3 dni po jutrze
          endDate: DateTime(dayAfterTomorrow.year, dayAfterTomorrow.month, dayAfterTomorrow.day, 19, 0), // 19:00
          location: 'Gdańsk, ul. Kocia 17',
          eventType: 'Warsztaty',
          participantsCount: 10,
          requiresRegistration: true,
        ),
      ];


      setState(() {
        _events = events;
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

      // Sortowanie wydarzeń wg daty (najbliższe na górze)
      _filteredEvents.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  // Format daty wydarzenia
  String _formatEventDate(DateTime date, DateTime? endDate) {
    final formatter = DateFormat('dd.MM.yyyy');
    final timeFormatter = DateFormat('HH:mm');

    String formattedDate = formatter.format(date);
    String formattedTime = timeFormatter.format(date);

    if (endDate != null) {
      if (formatter.format(date) == formatter.format(endDate)) {
        // Ten sam dzień
        return '$formattedDate, $formattedTime - ${timeFormatter.format(endDate)}';
      } else {
        // Różne dni
        return '$formattedDate $formattedTime - ${formatter.format(endDate)} ${timeFormatter.format(endDate)}';
      }
    }

    return '$formattedDate, $formattedTime';
  }

  // Sprawdź, czy data jest dzisiaj
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Sprawdź, czy data jest jutro
  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  // Pokaż informacje o wydarzeniu
  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEventDetailsSheet(event),
    );
  }

  // Budowanie bottom sheet z detalami wydarzenia
  Widget _buildEventDetailsSheet(Event event) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Uchwyt do przewijania
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Zdjęcie wydarzenia
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  event.imageUrl,
                  fit: BoxFit.cover,
                ),
                // Przyciemnienie na zdjęciu dla lepszej czytelności
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
                // Przycisk zamknięcia
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                // Etykieta typu wydarzenia
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
                // Tytuł wydarzenia na zdjęciu
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

          // Zawartość scrollowana
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informacje o organizatorze
                  Row(
                    children: [
                      Icon(Icons.home_work_outlined, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.organizerName,
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

                  // Data i czas wydarzenia
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
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isToday(event.date)
                                    ? 'Dzisiaj!'
                                    : _isTomorrow(event.date)
                                    ? 'Jutro!'
                                    : '',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Lokalizacja wydarzenia
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
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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

                  // Opis wydarzenia
                  Text(
                    'O wydarzeniu',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Liczba uczestników
                  if (event.participantsCount != null) ...[
                    Row(
                      children: [
                        Icon(Icons.people, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Liczba uczestników: ${event.participantsCount}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Informacja o rejestracji
                  if (event.requiresRegistration) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'To wydarzenie wymaga wcześniejszej rejestracji',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Przycisk dołączenia/rejestracji
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              event.requiresRegistration
                                  ? 'Przejście do formularza rejestracji'
                                  : 'Dołączono do wydarzenia',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        event.requiresRegistration ? 'Zarejestruj się' : 'Dołącz do wydarzenia',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Przycisk udostępniania
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
          ),
        ],
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
          // Search field
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
          // Filter chips
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Ładowanie wydarzeń...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
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

        // Add header with date if this is the first event or if the date differs from previous
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
      // Capitalize first letter
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with event type badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                ),
                // Badge for event type
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
                // Registration badge if required
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
            // Event details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time of the event
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
                  // Event title
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
                  // Organizer
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
                  // Location
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
                  const SizedBox(height: 12),
                  // Participants count with icon
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