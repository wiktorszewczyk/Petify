import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reservation_slot.dart';
import '../services/reservation_service.dart';
import '../services/pet_service.dart';
import '../services/cache/cache_manager.dart';
import '../styles/colors.dart';
import '../models/pet.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';

class VolunteerWalksView extends StatefulWidget {
  const VolunteerWalksView({super.key});

  @override
  State<VolunteerWalksView> createState() => _VolunteerWalksViewState();
}

class _VolunteerWalksViewState extends State<VolunteerWalksView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _reservationService = ReservationService();
  final _petService = PetService();

  List<ReservationSlot> _availableSlots = [];
  List<ReservationSlot> _myReservations = [];
  bool _isLoadingAvailable = false;
  bool _isLoadingMy = false;
  final Map<int, Pet> _petDetailsCache = {};

  DateTime _selectedDate = DateTime.now();
  bool _isCalendarView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCachedDataFirst();
  }

  Future<void> _loadCachedDataFirst() async {
    final cachedAvailable = CacheManager.get<List<ReservationSlot>>('available_slots');
    if (cachedAvailable != null) {
      print('💾 VolunteerWalks: Found cached available slots: ${cachedAvailable.length}');
      setState(() {
        _availableSlots = cachedAvailable;
        _isLoadingAvailable = false;
      });
      CacheManager.markStale('available_slots');
      _refreshAvailableSlotsInBackground();
    } else {
      print('🆙 VolunteerWalks: No cached available slots, loading fresh data');
      _loadAvailableSlots();
    }

    final cachedMy = CacheManager.get<List<ReservationSlot>>('my_reservations');
    if (cachedMy != null) {
      print('💾 VolunteerWalks: Found cached my reservations: ${cachedMy.length}');
      setState(() {
        _myReservations = cachedMy;
        _isLoadingMy = false;
      });
      CacheManager.markStale('my_reservations');
      _refreshMyReservationsInBackground();
    } else {
      print('🆙 VolunteerWalks: No cached my reservations, loading fresh data');
      _loadMyReservations();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    CacheManager.markStale('available_slots');
    setState(() {
      _isLoadingAvailable = true;
    });

    try {
      final slots = await _reservationService.getAvailableSlots();
      await _fetchPetDetailsForSlots(slots);
      setState(() {
        _availableSlots = slots;
        _isLoadingAvailable = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAvailable = false;
      });
      if (mounted) {
        if (e.toString().contains('403') || e.toString().contains('uprawnień')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funkcja dostępna tylko dla aktywnych wolontariuszy'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _refreshAvailableSlotsInBackground() async {
    try {
      final slots = await _reservationService.getAvailableSlots();
      await _fetchPetDetailsForSlots(slots);
      if (mounted) {
        setState(() {
          _availableSlots = slots;
        });
      }
    } catch (e) {
      print('Background available slots refresh failed: $e');
    }
  }

  Future<void> _loadMyReservations() async {
    CacheManager.markStale('my_reservations');
    setState(() {
      _isLoadingMy = true;
    });

    try {
      final slots = await _reservationService.getMyReservations();
      await _fetchPetDetailsForSlots(slots);
      setState(() {
        _myReservations = slots;
        _isLoadingMy = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMy = false;
      });
      if (mounted) {
        if (e.toString().contains('403') || e.toString().contains('uprawnień')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funkcja dostępna tylko dla aktywnych wolontariuszy'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _refreshMyReservationsInBackground() async {
    try {
      print('🔄 VolunteerWalks: Background refresh of my reservations...');
      final slots = await _reservationService.getMyReservations();
      await _fetchPetDetailsForSlots(slots);
      if (mounted) {
        setState(() {
          _myReservations = slots;
        });
        print('✅ VolunteerWalks: Background refresh completed, now have ${slots.length} my reservations');
      }
    } catch (e) {
      print('❌ VolunteerWalks: Background my reservations refresh failed: $e');
    }
  }

  /// Force refresh both tabs immediately after reservation changes
  Future<void> _forceRefreshBothTabs() async {
    try {
      print('🔄 VolunteerWalks: Starting force refresh of both tabs...');

      // Completely clear cache to force fresh API calls
      CacheManager.invalidate('available_slots');
      CacheManager.invalidate('my_reservations');
      CacheManager.invalidatePattern('reservation_');

      // Set loading states
      if (mounted) {
        setState(() {
          _isLoadingAvailable = true;
          _isLoadingMy = true;
        });
      }

      // Fetch both in parallel with fresh data - use forceRefresh to bypass cache
      final futures = await Future.wait([
        _reservationService.cachedFetch('available_slots_fresh', () => _reservationService.getAvailableSlots(), forceRefresh: true),
        _reservationService.cachedFetch('my_reservations_fresh', () => _reservationService.getMyReservations(), forceRefresh: true),
      ]);

      final availableSlots = futures[0] as List<ReservationSlot>;
      final myReservations = futures[1] as List<ReservationSlot>;

      print('📊 VolunteerWalks: Fetched ${availableSlots.length} available, ${myReservations.length} my reservations');

      // Batch fetch pet details for both lists combined
      final allSlots = [...availableSlots, ...myReservations];
      await _fetchPetDetailsForSlots(allSlots);

      if (mounted) {
        setState(() {
          _availableSlots = availableSlots;
          _myReservations = myReservations;
          _isLoadingAvailable = false;
          _isLoadingMy = false;
        });
        print('✅ VolunteerWalks: UI updated with fresh data');
      }

      print('✅ VolunteerWalks: Force refresh completed successfully');
    } catch (e) {
      print('❌ VolunteerWalks: Force refresh failed: $e');
      if (mounted) {
        setState(() {
          _isLoadingAvailable = false;
          _isLoadingMy = false;
        });
      }
    }
  }

  Future<void> _reserveSlot(ReservationSlot slot) async {
    print('🔄 VolunteerWalks: Starting reservation for slot ${slot.id}');

    final response = await _reservationService.reserveSlot(slot.id);

    if (mounted) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ VolunteerWalks: Slot ${slot.id} reserved successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Termin został zarezerwowany!'),
            backgroundColor: Colors.green,
          ),
        );

        // Switch to "My Reservations" tab first
        _tabController.animateTo(1);

        // Wait a moment for tab animation, then force refresh
        await Future.delayed(const Duration(milliseconds: 200));

        // Force immediate refresh of both tabs
        await _forceRefreshBothTabs();

        print('✅ VolunteerWalks: Reservation process completed');
      } else {
        String errorMessage = 'Nie udało się zarezerwować terminu';
        if (response.data is Map<String, dynamic>) {
          final errorData = response.data as Map<String, dynamic>;
          if (errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          }
        }
        print('❌ VolunteerWalks: Reservation failed: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelReservation(ReservationSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Anuluj rezerwację',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Czy na pewno chcesz anulować rezerwację spaceru?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nie'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tak, anuluj'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      print('🔄 VolunteerWalks: Starting cancellation for slot ${slot.id}');

      final response = await _reservationService.cancelReservation(slot.id);

      if (mounted) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          print('✅ VolunteerWalks: Slot ${slot.id} cancelled successfully');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezerwacja została anulowana'),
              backgroundColor: Colors.orange,
            ),
          );

          // Force immediate refresh of both tabs
          await _forceRefreshBothTabs();

          print('✅ VolunteerWalks: Cancellation process completed');
        } else {
          String errorMessage = 'Nie udało się anulować rezerwacji';
          if (response.data is Map<String, dynamic>) {
            final errorData = response.data as Map<String, dynamic>;
            if (errorData.containsKey('error')) {
              errorMessage = errorData['error'].toString();
            }
          }
          print('❌ VolunteerWalks: Cancellation failed: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _fetchPetDetailsForSlots(List<ReservationSlot> slots) async {
    final allIds = slots.map((s) => s.petId).toList();
    final idsToFetch = allIds.where((id) => !_petDetailsCache.containsKey(id)).toList();

    if (idsToFetch.isEmpty) {
      return;
    }

    try {
      print('🔍 VolunteerWalks: Batch fetching ${idsToFetch.length} pet details...');
      final petsMap = await _petService.getPetsByIds(idsToFetch);
      _petDetailsCache.addAll(petsMap);
      print('✅ VolunteerWalks: Successfully cached ${petsMap.length} pet details');
    } catch (e) {
      print('❌ VolunteerWalks: Batch fetch failed: $e');
      // Fallback to individual fetching only for critical UI cases
      if (idsToFetch.length <= 10) {
        for (final id in idsToFetch.take(5)) { // Limit to prevent overload
          try {
            final pet = await _petService.getPetById(id);
            _petDetailsCache[id] = pet;
          } catch (e) {
            print('❌ Individual fetch failed for pet $id: $e');
          }
        }
      }
    }
  }

  Future<void> _showSlotDetails(ReservationSlot slot) async {
    Pet? pet = _petDetailsCache[slot.petId];
    if (pet == null) {
      try {
        pet = await _petService.getPetById(slot.petId);
        _petDetailsCache[slot.petId] = pet;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się pobrać szczegółów: $e')),
        );
        return;
      }
    }

    if (!mounted || pet == null) return;

    showDialog(
      context: context,
      builder: (context) => _buildEnhancedDetailsDialog(slot, pet!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Spacery z psami',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
          tabs: const [
            Tab(text: 'Dostępne terminy'),
            Tab(text: 'Moje rezerwacje'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableSlotsTab(),
          _buildMyReservationsTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableSlotsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _forceRefreshBothTabs();
      },
      child: Column(
        children: [
          _buildViewToggle(),
          if (_availableSlots.length > 100)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Znaleziono ${_availableSlots.length} terminów. Widok może ładować się dłużej.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoadingAvailable
                ? const Center(child: CircularProgressIndicator())
                : _availableSlots.isEmpty
                ? _buildEmptyState(
              icon: Icons.event_available,
              title: 'Brak dostępnych terminów',
              subtitle: 'Sprawdź ponownie później lub skontaktuj się ze schroniskiem',
            )
                : _isCalendarView
                ? _buildCalendarView(_availableSlots, false)
                : _buildListView(_availableSlots, false),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReservationsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _forceRefreshBothTabs();
      },
      child: Column(
        children: [
          _buildViewToggle(),
          if (_myReservations.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Masz ${_myReservations.length} aktywn${_myReservations.length == 1 ? 'ą' : 'ych'} rezerwacj${_myReservations.length == 1 ? 'ę' : 'i'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoadingMy
                ? const Center(child: CircularProgressIndicator())
                : _myReservations.isEmpty
                ? _buildEmptyState(
              icon: Icons.event_note,
              title: 'Brak rezerwacji',
              subtitle: 'Zarezerwuj termin w zakładce "Dostępne terminy"',
            )
                : _isCalendarView
                ? _buildCalendarView(_myReservations, true)
                : _buildListView(_myReservations, true),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCalendarView = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isCalendarView ? AppColors.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: _isCalendarView ? Colors.black : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kalendarz',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _isCalendarView ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCalendarView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isCalendarView ? AppColors.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list,
                      color: !_isCalendarView ? Colors.black : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lista',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: !_isCalendarView ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(List<ReservationSlot> slots, bool isReservation) {
    final Map<DateTime, List<ReservationSlot>> slotsByDate = {};
    for (final slot in slots) {
      final date = DateTime(slot.startTime.year, slot.startTime.month, slot.startTime.day);
      slotsByDate.putIfAbsent(date, () => []).add(slot);
    }

    final sortedDates = slotsByDate.keys.toList()..sort();

    return Column(
      children: [
        _buildCalendarHeader(),
        Expanded(
          child: sortedDates.isEmpty
              ? _buildEmptyCalendar()
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dateSlots = slotsByDate[date]!;
              return _buildDateSection(date, dateSlots, isReservation);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Dostępne terminy',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('MMMM yyyy', 'pl_PL').format(DateTime.now()),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCalendar() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Brak terminów w kalendarzu',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(DateTime date, List<ReservationSlot> slots, bool isReservation) {
    final isToday = _isSameDay(date, DateTime.now());
    final isTomorrow = _isSameDay(date, DateTime.now().add(const Duration(days: 1)));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : isTomorrow
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primaryColor
                        : isTomorrow
                        ? Colors.blue
                        : Colors.grey[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('d', 'pl_PL').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDateDisplayName(date),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMMM', 'pl_PL').format(date),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${slots.length} ${slots.length == 1 ? 'termin' : 'terminów'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...slots.map((slot) => _buildCompactSlotCard(slot, isReservation)).toList(),
        ],
      ),
    );
  }

  Widget _buildCompactSlotCard(ReservationSlot slot, bool isReservation) {
    final pet = _petDetailsCache[slot.petId];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: pet?.imageUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                pet!.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.pets,
                  color: AppColors.primaryColor,
                ),
              ),
            )
                : Icon(
              Icons.pets,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet?.name ?? 'Pies #${slot.petId}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (pet?.breed != null)
                  Text(
                    pet!.breed!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeRange(slot.startTime, slot.endTime),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(slot.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(slot.status),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(slot.status),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _showSlotDetails(slot),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (!isReservation && slot.status == 'AVAILABLE')
                    GestureDetector(
                      onTap: () => _reserveSlot(slot),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  if (isReservation && slot.status == 'RESERVED')
                    GestureDetector(
                      onTap: () => _cancelReservation(slot),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<ReservationSlot> slots, bool isReservation) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        return _buildSlotCard(slot, isReservation: isReservation);
      },
    );
  }

  Widget _buildEnhancedDetailsDialog(ReservationSlot slot, Pet pet) {
    final distanceText = pet.distance != null
        ? LocationService().formatDistance(pet.distance!)
        : 'Brak danych';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryColor.withOpacity(0.8),
                    AppColors.primaryColor,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  if (pet.imageUrl != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          pet.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            child: Icon(
                              Icons.pets,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        color: AppColors.primaryColor.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.pets,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                        if (pet.breed != null)
                          Text(
                            pet.breed!,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      Icons.schedule,
                      'Termin spaceru',
                      _formatDateTime(slot.startTime, slot.endTime),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.home,
                      'Schronisko',
                      pet.shelterName ?? 'Brak informacji',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.location_on,
                      'Adres',
                      pet.shelterAddress ?? 'Brak informacji',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.near_me,
                      'Odległość',
                      distanceText,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPetInfoChip(
                            pet.genderDisplayName,
                            pet.gender == 'male' ? Icons.male : Icons.female,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPetInfoChip(
                            '${pet.age} ${pet.age == 1 ? 'rok' : 'lat'}',
                            Icons.cake,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPetInfoChip(
                            pet.sizeDisplayName,
                            Icons.straighten,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(slot.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(slot.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Status: ${_getStatusText(slot.status)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(slot.status),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPetInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDateDisplayName(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return 'Dzisiaj';
    } else if (_isSameDay(date, now.add(const Duration(days: 1)))) {
      return 'Jutro';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Wczoraj';
    }
    return DateFormat('EEEE', 'pl_PL').format(date);
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${DateFormat('HH:mm').format(start)}-${DateFormat('HH:mm').format(end)}';
  }

  Widget _buildSlotCard(ReservationSlot slot, {required bool isReservation}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pets,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _petDetailsCache[slot.petId]?.name != null
                            ? 'Spacer z ${_petDetailsCache[slot.petId]!.name}'
                            : 'Spacer z psem #${slot.petId}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_petDetailsCache[slot.petId]?.breed != null)
                        Text(
                          _petDetailsCache[slot.petId]!.breed!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        _formatDateTime(slot.startTime, slot.endTime),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(slot.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(slot.status),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(slot.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (slot.reservedBy != null) ...[
              Text(
                'Zarezerwowane przez: ${slot.reservedBy}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showSlotDetails(slot),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Szczegóły',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isReservation && slot.status == 'AVAILABLE')
                  ElevatedButton(
                    onPressed: () => _reserveSlot(slot),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Zarezerwuj',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                if (isReservation && slot.status == 'RESERVED')
                  OutlinedButton(
                    onPressed: () => _cancelReservation(slot),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Anuluj',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime start, DateTime end) {
    final dateStr = '${start.day}.${start.month}.${start.year}';
    final timeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$dateStr, $timeStr';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return Colors.green;
      case 'RESERVED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return 'Dostępny';
      case 'RESERVED':
        return 'Zarezerwowany';
      case 'CANCELLED':
        return 'Anulowany';
      default:
        return 'Nieznany';
    }
  }
}