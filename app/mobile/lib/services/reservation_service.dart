import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/basic_response.dart';
import '../models/reservation_slot.dart';
import 'api/initial_api.dart';
import 'cache/cache_manager.dart';

class ReservationService with CacheableMixin {
  final _api = InitialApi().dio;
  static ReservationService? _instance;
  factory ReservationService() => _instance ??= ReservationService._();
  ReservationService._();

  String _extractProblemDetail(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
    }
    return '$fallback: ${e.message}';
  }

  /// Pobiera dostępne sloty do rezerwacji (tylko dla wolontariuszy)
  Future<List<ReservationSlot>> getAvailableSlots() async {
    final cacheKey = 'available_slots';

    return cachedFetch(cacheKey, () async {
      try {
        dev.log('ReservationService: Requesting available slots...');
        final response = await _api.get('/reservations/slots/available');
        dev.log('ReservationService: Response status: ${response.statusCode}');
        dev.log('ReservationService: Response data type: ${response.data.runtimeType}');

        if (response.statusCode == 200 && response.data is List) {
          final slotsData = response.data as List;
          dev.log('ReservationService: Received ${slotsData.length} slots');
          return slotsData.map((slotJson) => ReservationSlot.fromJson(slotJson)).toList();
        }

        throw Exception('Nieprawidłowa odpowiedź serwera');
      } on DioException catch (e) {
        dev.log('Błąd podczas pobierania dostępnych slotów: ${e.message}');
        dev.log('Status code: ${e.response?.statusCode}');
        dev.log('Response data: ${e.response?.data}');

        if (e.response?.statusCode == 403) {
          throw Exception('Brak uprawnień. Tylko wolontariusze mogą przeglądać dostępne terminy.');
        }

        throw Exception(_extractProblemDetail(e, 'Nie udało się pobrać dostępnych terminów'));
      } catch (e) {
        dev.log('Unexpected error in getAvailableSlots: $e');
        throw Exception('Nieoczekiwany błąd: $e');
      }
    }, ttl: Duration(minutes: 5));
  }

  /// Pobiera moje rezerwacje (jako wolontariusz)
  Future<List<ReservationSlot>> getMyReservations() async {
    final cacheKey = 'my_reservations';

    return cachedFetch(cacheKey, () async {
      try {
        dev.log('ReservationService: Requesting my reservations...');
        final response = await _api.get('/reservations/my-slots');
        dev.log('ReservationService: My slots response status: ${response.statusCode}');
        dev.log('ReservationService: My slots response data type: ${response.data.runtimeType}');

        if (response.statusCode == 200 && response.data is List) {
          final slotsData = response.data as List;
          dev.log('ReservationService: Received ${slotsData.length} my reservations');
          return slotsData.map((slotJson) => ReservationSlot.fromJson(slotJson)).toList();
        }

        throw Exception('Nieprawidłowa odpowiedź serwera');
      } on DioException catch (e) {
        dev.log('Błąd podczas pobierania moich rezerwacji: ${e.message}');
        dev.log('My slots status code: ${e.response?.statusCode}');
        dev.log('My slots response data: ${e.response?.data}');

        if (e.response?.statusCode == 403) {
          throw Exception('Brak uprawnień. Tylko wolontariusze mogą przeglądać swoje rezerwacje.');
        }

        throw Exception(_extractProblemDetail(e, 'Nie udało się pobrać twoich rezerwacji'));
      } catch (e) {
        dev.log('Unexpected error in getMyReservations: $e');
        throw Exception('Nieoczekiwany błąd: $e');
      }
    }, ttl: Duration(minutes: 3));
  }

  /// Rezerwuje slot na spacer z psem
  Future<BasicResponse> reserveSlot(int slotId) async {
    try {
      final response = await _api.patch('/reservations/slots/$slotId/reserve');

      if (response.statusCode == 200 || response.statusCode == 201) {
        CacheManager.invalidatePattern('available_slots');
        CacheManager.invalidatePattern('my_reservations');
        CacheManager.invalidatePattern('pet_slots');
      }

      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas rezerwacji slotu: ${e.message}');
      final status = e.response?.statusCode ?? 0;
      final data = e.response?.data;

      String errorMessage = 'Nie udało się zarezerwować terminu';

      if (status == 403) {
        errorMessage = 'Brak uprawnień. Tylko wolontariusze mogą rezerwować terminy.';
      } else if (status == 409) {
        errorMessage = 'Ten termin jest już zarezerwowany';
      } else if (status == 404) {
        errorMessage = 'Nie znaleziono terminu';
      } else if (data is Map<String, dynamic> && data.containsKey('detail')) {
        errorMessage = data['detail'].toString();
      }

      return BasicResponse(status, {'error': errorMessage});
    } catch (e) {
      dev.log('Nieoczekiwany błąd podczas rezerwacji: $e');
      return BasicResponse(0, {'error': 'Nieoczekiwany błąd: ${e.toString()}'});
    }
  }

  /// Anuluje rezerwację
  Future<BasicResponse> cancelReservation(int slotId) async {
    try {
      final response = await _api.patch('/reservations/slots/$slotId/cancel');

      if (response.statusCode == 200 || response.statusCode == 204) {
        CacheManager.invalidatePattern('available_slots');
        CacheManager.invalidatePattern('my_reservations');
        CacheManager.invalidatePattern('pet_slots');
      }

      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas anulowania rezerwacji: ${e.message}');
      final status = e.response?.statusCode ?? 0;
      final data = e.response?.data;

      String errorMessage = 'Nie udało się anulować rezerwacji';

      if (status == 403) {
        errorMessage = 'Brak uprawnień do anulowania tej rezerwacji';
      } else if (status == 404) {
        errorMessage = 'Nie znaleziono rezerwacji';
      } else if (data is Map<String, dynamic> && data.containsKey('detail')) {
        errorMessage = data['detail'].toString();
      }

      return BasicResponse(status, {'error': errorMessage});
    } catch (e) {
      dev.log('Nieoczekiwany błąd podczas anulowania: $e');
      return BasicResponse(0, {'error': 'Nieoczekiwany błąd: ${e.toString()}'});
    }
  }

  /// Pobiera sloty dla konkretnego psa
  Future<List<ReservationSlot>> getSlotsByPet(int petId) async {
    final cacheKey = 'pet_slots_$petId';

    return cachedFetch(cacheKey, () async {
      try {
        final response = await _api.get('/reservations/slots/pet/$petId');

        if (response.statusCode == 200 && response.data is List) {
          final slotsData = response.data as List;
          return slotsData.map((slotJson) => ReservationSlot.fromJson(slotJson)).toList();
        }

        throw Exception('Nieprawidłowa odpowiedź serwera');
      } on DioException catch (e) {
        dev.log('Błąd podczas pobierania slotów dla psa: ${e.message}');
        throw Exception('Nie udało się pobrać terminów dla tego psa: ${e.message}');
      }
    }, ttl: Duration(minutes: 8));
  }
}