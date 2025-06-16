import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reservation_slot.dart';
import '../services/reservation_service.dart';
import '../services/pet_service.dart';
import '../styles/colors.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailableSlots();
    _loadMyReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoadingAvailable = true;
    });

    try {
      final slots = await _reservationService.getAvailableSlots();
      setState(() {
        _availableSlots = slots;
        _isLoadingAvailable = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAvailable = false;
      });
      if (mounted) {
        // Check if error is related to insufficient permissions
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

  Future<void> _loadMyReservations() async {
    setState(() {
      _isLoadingMy = true;
    });

    try {
      final slots = await _reservationService.getMyReservations();
      setState(() {
        _myReservations = slots;
        _isLoadingMy = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMy = false;
      });
      if (mounted) {
        // Check if error is related to insufficient permissions
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

  Future<void> _reserveSlot(ReservationSlot slot) async {
    final response = await _reservationService.reserveSlot(slot.id);

    if (mounted) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Termin został zarezerwowany!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAvailableSlots();
        _loadMyReservations();
      } else {
        String errorMessage = 'Nie udało się zarezerwować terminu';
        if (response.data is Map<String, dynamic>) {
          final errorData = response.data as Map<String, dynamic>;
          if (errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          }
        }
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
      final response = await _reservationService.cancelReservation(slot.id);

      if (mounted) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezerwacja została anulowana'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadAvailableSlots();
          _loadMyReservations();
        } else {
          String errorMessage = 'Nie udało się anulować rezerwacji';
          if (response.data is Map<String, dynamic>) {
            final errorData = response.data as Map<String, dynamic>;
            if (errorData.containsKey('error')) {
              errorMessage = errorData['error'].toString();
            }
          }
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
      onRefresh: _loadAvailableSlots,
      child: _isLoadingAvailable
          ? const Center(child: CircularProgressIndicator())
          : _availableSlots.isEmpty
          ? _buildEmptyState(
        icon: Icons.event_available,
        title: 'Brak dostępnych terminów',
        subtitle: 'Sprawdź ponownie później lub skontaktuj się ze schroniskiem',
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableSlots.length,
        itemBuilder: (context, index) {
          final slot = _availableSlots[index];
          return _buildSlotCard(slot, isReservation: false);
        },
      ),
    );
  }

  Widget _buildMyReservationsTab() {
    return RefreshIndicator(
      onRefresh: _loadMyReservations,
      child: _isLoadingMy
          ? const Center(child: CircularProgressIndicator())
          : _myReservations.isEmpty
          ? _buildEmptyState(
        icon: Icons.event_note,
        title: 'Brak rezerwacji',
        subtitle: 'Zarezerwuj termin w zakładce "Dostępne terminy"',
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myReservations.length,
        itemBuilder: (context, index) {
          final slot = _myReservations[index];
          return _buildSlotCard(slot, isReservation: true);
        },
      ),
    );
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
                        'Spacer z psem #${slot.petId}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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