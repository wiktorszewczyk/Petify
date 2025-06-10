import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/basic_response.dart';
import '../services/token_repository.dart';
import 'api/initial_api.dart';

class VolunteerService {
  final _api = InitialApi().dio;
  static VolunteerService? _instance;
  factory VolunteerService() => _instance ??= VolunteerService._();
  VolunteerService._();

  /// Wysyła wniosek o zostanie wolontariuszem
  Future<BasicResponse> submitApplication(Map<String, dynamic> applicationData) async {
    try {
      final resp = await _api.post(
        '/volunteer/apply',
        data: applicationData,
      );
      return BasicResponse(resp.statusCode ?? 0, resp.data);
    } on DioException catch (e) {
      dev.log('submitApplication error: ${e.message}');
      final status = e.response?.statusCode ?? 0;
      final data = e.response?.data;

      if (status == 400 && data is Map<String, dynamic>) {
        return BasicResponse(status, {'error': data['detail'] ?? 'Błąd walidacji danych'});
      } else if (status == 409) {
        return BasicResponse(status, {'error': 'Już posiadasz aktywny wniosek o wolontariat'});
      } else {
        return BasicResponse(status, {'error': 'Nie udało się wysłać wniosku: $status'});
      }
    } catch (e) {
      return BasicResponse(0, {'error': 'Nieznany błąd: $e'});
    }
  }

  /// Pobiera całą historię wniosków użytkownika
  Future<BasicResponse> getApplicationHistory() async {
    try {
      final resp = await _api.get('/volunteer/apply');
      return BasicResponse(resp.statusCode ?? 0, resp.data);
    } on DioException catch (e) {
      dev.log('getApplicationHistory error: ${e.message}');
      final status = e.response?.statusCode ?? 0;
      return BasicResponse(status, {'error': 'Nie udało się pobrać historii: $status'});
    } catch (e) {
      return BasicResponse(0, {'error': 'Nieznany błąd: $e'});
    }
  }
}
