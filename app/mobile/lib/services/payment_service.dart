import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/donation.dart';
import '../models/basic_response.dart';
import 'api/initial_api.dart';

class PaymentService {
  final _api = InitialApi().dio;
  static PaymentService? _instance;

  factory PaymentService() => _instance ??= PaymentService._();
  PaymentService._();

  /// Tworzy intention donacji i zwraca dostępne opcje płatności
  Future<PaymentOptionsResponse> createDonationIntent({
    required int shelterId,
    int? petId,
    int? fundraiserId,
    required String donationType, // 'MONEY' lub 'MATERIAL'
    double? amount,
    String? message,
    bool anonymous = false,
    String? itemName,
    double? unitPrice,
    int? quantity,
  }) async {
    try {
      if (donationType == 'MONEY' && amount == null) {
        throw Exception('Amount is required for monetary donations');
      }

      final requestData = <String, dynamic>{
        'shelterId': shelterId,
        'donationType': donationType,
        'anonymous': anonymous,
      };

      if (amount != null) requestData['amount'] = amount;
      if (petId != null) requestData['petId'] = petId;
      if (fundraiserId != null) requestData['fundraiserId'] = fundraiserId;
      if (message != null) requestData['message'] = message;
      if (itemName != null) requestData['itemName'] = itemName;
      if (unitPrice != null) requestData['unitPrice'] = unitPrice;
      if (quantity != null) requestData['quantity'] = quantity;

      dev.log('Creating donation intent with data: $requestData');

      final response = await _api.post('/donations/intent', data: requestData);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return PaymentOptionsResponse.fromJson(response.data);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas tworzenia intention donacji: ${e.message}');
      throw Exception('Nie udało się utworzyć donacji: ${e.message}');
    }
  }

  /// Inicjalizuje płatność z wybranym dostawcą
  Future<PaymentInitializationResponse> initializePayment({
    required int donationId,
    required String sessionToken,
    required String provider, // 'PAYU' lub 'STRIPE'
    String? returnUrl,
    String? cancelUrl,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'provider': provider,
        'returnUrl': returnUrl ?? 'https://petify.com/payment/success',
        'cancelUrl': cancelUrl ?? 'https://petify.com/payment/cancel',
      };

      dev.log('Initializing payment for donation $donationId with provider $provider and data: $requestData');

      final response = await _api.post(
        '/donations/$donationId/payment/initialize',
        data: requestData,
        options: Options(
          headers: {
            'Session-Token': sessionToken,
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return PaymentInitializationResponse.fromJson(response.data);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas inicjalizacji płatności: ${e.message}');
      throw Exception('Nie udało się zainicjalizować płatności: ${e.message}');
    }
  }

  /// Sprawdza status płatności
  Future<DonationWithPaymentStatusResponse> getPaymentStatus(int donationId) async {
    try {
      final response = await _api.get('/donations/payment-status/$donationId');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return DonationWithPaymentStatusResponse.fromJson(response.data);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas sprawdzania statusu płatności: ${e.message}');
      throw Exception('Nie udało się sprawdzić statusu płatności: ${e.message}');
    }
  }

  /// Anuluje donację
  Future<BasicResponse> cancelDonation(int donationId) async {
    try {
      final response = await _api.put('/donations/$donationId/cancel');
      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas anulowania donacji: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

  /// Oblicza opłaty za płatność
  Future<PaymentFeeCalculation> calculateFees({
    required double amount,
    required String provider,
  }) async {
    try {
      final requestData = {
        'amount': amount,
        'provider': provider,
      };

      final response = await _api.post('/payments/calculate-fee', data: requestData);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return PaymentFeeCalculation.fromJson(response.data);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas obliczania opłat: ${e.message}');
      throw Exception('Nie udało się obliczyć opłat: ${e.message}');
    }
  }

  /// Pobiera obsługiwane metody płatności dla danego dostawcy
  Future<List<String>> getPaymentMethods(String provider) async {
    try {
      final response = await _api.get('/payments/methods/$provider');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).cast<String>();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania metod płatności: ${e.message}');
      throw Exception('Nie udało się pobrać metod płatności: ${e.message}');
    }
  }

  /// Pobiera historię donacji użytkownika
  Future<List<DonationResponse>> getUserDonations() async {
    try {
      final response = await _api.get('/donations/my');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => DonationResponse.fromJson(json))
            .toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania historii donacji: ${e.message}');
      throw Exception('Nie udało się pobrać historii donacji: ${e.message}');
    }
  }

  /// Pobiera główną zbiórkę schroniska
  Future<FundraiserResponse?> getShelterMainFundraiser(int shelterId) async {
    try {
      final response = await _api.get('/fundraisers/shelter/$shelterId/main');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return FundraiserResponse.fromJson(response.data);
      }

      return null; // Schronisko nie ma głównej zbiórki
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Schronisko nie ma głównej zbiórki
      }
      dev.log('Błąd podczas pobierania głównej zbiórki: ${e.message}');
      throw Exception('Nie udało się pobrać zbiórki: ${e.message}');
    }
  }

  /// Pobiera wszystkie zbiórki schroniska
  Future<List<FundraiserResponse>> getShelterFundraisers(int shelterId) async {
    try {
      final response = await _api.get('/fundraisers/shelter/$shelterId');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final content = response.data['content'] as List? ?? [];
        return content.map((json) => FundraiserResponse.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania zbiórek schroniska: ${e.message}');
      throw Exception('Nie udało się pobrać zbiórek: ${e.message}');
    }
  }
}