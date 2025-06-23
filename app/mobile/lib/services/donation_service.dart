import 'dart:async';
import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/donation.dart';
import 'api/initial_api.dart';
import 'cache/cache_manager.dart';
import 'cache/cache_scheduler.dart';

class DonationService with CacheableMixin {
  final _api = InitialApi().dio;
  static DonationService? _instance;

  factory DonationService() => _instance ??= DonationService._();

  DonationService._();

  // Pobranie wszystkich donacji użytkownika
  Future<List<Donation>> getUserDonations() async {
    const cacheKey = 'user_donations';

    return cachedFetch(cacheKey, () async {
      try {
        final response = await _api.get('/donations/my');

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          final content = data['content'] as List? ?? [];

          return content.map((donationJson) =>
              Donation.fromBackendJson(donationJson)).toList();
        }

        throw Exception('Nieprawidłowa odpowiedź serwera');
      } on DioException catch (e) {
        dev.log('Błąd podczas pobierania donacji użytkownika: ${e.message}');
        return <Donation>[];
      }
    }, ttl: Duration(minutes: 15));
  }

  // Dodanie nowej donacji materialnej (dla konkretnego zwierzaka)
  Future<Donation> addMaterialDonation({
    required int shelterId,
    required int petId,
    required MaterialDonationItem item,
    required int quantity,
    String? message,
  }) async {
    try {
      final donationIntentResponse = await _api.post(
          '/donations/intent', data: {
        'shelterId': shelterId,
        'petId': petId,
        'donationType': 'MATERIAL',
        'amount': item.price * quantity,
        'message': message,
        'anonymous': false,
        'itemName': item.apiName,
        'unitPrice': item.price,
        'quantity': quantity,
      });

      if (donationIntentResponse.statusCode == 200) {
        final donationData = donationIntentResponse.data['donation'];
        // Oznacz cache jako nieświeży po dodaniu donacji materialnej
        CacheManager.markStalePattern('user_donations');
        CacheManager.markStalePattern('shelter_');
        CacheManager.markStalePattern('fundraiser_');
        CacheScheduler.forceRefreshCriticalData();
        dev.log('🗑️ DonationService: Marked cache as stale after adding material donation');
        return Donation.fromBackendJson(donationData);
      }

      throw Exception('Nie udało się utworzyć donacji');
    } on DioException catch (e) {
      dev.log('Błąd podczas tworzenia donacji materialnej: ${e.message}');
      return Donation.material(
        shelterName: 'Schronisko $shelterId',
        petId: petId.toString(),
        item: item,
        quantity: quantity,
        message: message,
      );
    }
  }

  // Dodanie donacji pieniężnej (dla schroniska)
  Future<Donation> addMonetaryDonation({
    required int shelterId,
    required double amount,
    String? message,
    int? fundraiserId,
  }) async {
    try {
      final requestData = {
        'shelterId': shelterId,
        'donationType': 'MONEY',
        'amount': amount,
        'message': message,
        'anonymous': false,
      };

      if (fundraiserId != null) {
        requestData['fundraiserId'] = fundraiserId;
      }

      final donationIntentResponse = await _api.post(
          '/donations/intent', data: requestData);

      if (donationIntentResponse.statusCode == 200) {
        final donationData = donationIntentResponse.data['donation'];
        // Invalidate cache po dodaniu donacji pieniężnej
        CacheManager.markStalePattern('user_donations');
        CacheManager.markStalePattern('shelter_');
        CacheManager.markStalePattern('fundraiser_');
        CacheScheduler.forceRefreshCriticalData();
        dev.log('🗑️ DonationService: Marked cache as stale after adding monetary donation');
        return Donation.fromBackendJson(donationData);
      }

      throw Exception('Nie udało się utworzyć donacji');
    } on DioException catch (e) {
      dev.log('Błąd podczas tworzenia donacji pieniężnej: ${e.message}');
      return Donation.monetary(
        shelterName: 'Schronisko $shelterId',
        amount: amount,
        message: message,
      );
    }
  }

  // Pobranie dostępnych przedmiotów do donacji materialnej
  Future<List<MaterialDonationItem>> getAvailableMaterialItems() async {
    return MaterialDonationItem.getAvailableItems();
  }

  /// Pobiera opcje płatności dla donacji
  Future<Map<String, dynamic>> getPaymentOptions(int donationId) async {
    try {
      final response = await _api.get('/donations/$donationId');

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Nie udało się pobrać opcji płatności');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania opcji płatności: ${e.message}');
      throw Exception('Nie udało się pobrać opcji płatności: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> calculatePaymentFee(double amount,
      String provider) async {
    try {
      final response = await _api.post('/payments/calculate-fee', data: {
        'amount': amount,
        'provider': provider,
      });

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Nie udało się obliczyć opłat');
    } on DioException catch (e) {
      dev.log('Błąd podczas obliczania opłat: ${e.message}');
      final serviceFee = amount * 0.029;
      return {
        'totalAmount': amount,
        'serviceFee': serviceFee,
        'netAmount': amount - serviceFee,
        'provider': provider,
      };
    }
  }

  /// Inicjalizuje płatność
  Future<Map<String, dynamic>> initializePayment({
    required int donationId,
    required String provider,
    required String paymentMethod,
    required String sessionToken,
  }) async {
    try {
      final response = await _api.post(
        '/donations/$donationId/payment/initialize',
        data: {
          'provider': provider,
          'paymentMethod': paymentMethod,
        },
        options: Options(headers: {
          'Session-Token': sessionToken,
        }),
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Nie udało się zainicjować płatności');
    } on DioException catch (e) {
      dev.log('Błąd podczas inicjalizacji płatności: ${e.message}');
      throw Exception('Nie udało się zainicjować płatności: ${e.message}');
    }
  }

  /// Sprawdza status płatności
  Future<Map<String, dynamic>> checkPaymentStatus(int donationId) async {
    try {
      final response = await _api.get('/donations/payment-status/$donationId');

      if (response.statusCode == 200) {
        final paymentStatus = response.data['status'];
        if (paymentStatus == 'COMPLETED' || paymentStatus == 'SUCCESS') {
          CacheManager.invalidatePattern('user_donations');
          CacheManager.invalidatePattern('shelter_');
          CacheManager.invalidatePattern('fundraiser_');
          dev.log('🗑️ DonationService: Invalidated cache after successful payment');
        }
        return response.data;
      }

      throw Exception('Nie udało się sprawdzić statusu płatności');
    } on DioException catch (e) {
      dev.log('Błąd podczas sprawdzania statusu płatności: ${e.message}');
      throw Exception(
          'Nie udało się sprawdzić statusu płatności: ${e.message}');
    }
  }
}