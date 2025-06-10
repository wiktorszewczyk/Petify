import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/basic_response.dart';
import '../models/reservation_slot.dart';
import 'api/initial_api.dart';

class ReservationService {
  final _api = InitialApi().dio;
  static ReservationService? _instance;
  factory ReservationService() => _instance ??= ReservationService._();
  ReservationService._();

  /// Pobiera dostępne sloty do rezerwacji (tylko dla wolontariuszy)
  Future<List<ReservationSlot>> getAvailableSlots() async {
    try {
      final response = await _api.get('/reservations/slots/available');

      if (response.statusCode == 200 && response.data is List) {
        final slotsData = response.data as List;
        return slotsData.map((slotJson) => ReservationSlot.fromJson(slotJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania dostępnych slotów: ${e.message}');

      if (e.response?.statusCode == 403) {
        throw Exception('Brak uprawnień. Tylko wolontariusze mogą przeglądać dostępne terminy.');
      }

      throw Exception('Nie udało się pobrać dostępnych terminów: ${e.message}');
    }
  }

  /// Pobiera moje rezerwacje (jako wolontariusz)
  Future<List<ReservationSlot>> getMyReservations() async {
    try {
      final response = await _api.get('/reservations/my-slots');

      if (response.statusCode == 200 && response.data is List) {
        final slotsData = response.data as List;
        return slotsData.map((slotJson) => ReservationSlot.fromJson(slotJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania moich rezerwacji: ${e.message}');

      if (e.response?.statusCode == 403) {
        throw Exception('Brak uprawnień. Tylko wolontariusze mogą przeglądać swoje rezerwacje.');
      }

      throw Exception('Nie udało się pobrać twoich rezerwacji: ${e.message}');
    }
  }

  /// Rezerwuje slot na spacer z psem
  Future<BasicResponse> reserveSlot(int slotId) async {
    try {
      final response = await _api.patch('/reservations/slots/$slotId/reserve');
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
  }
}