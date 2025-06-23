import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/basic_response.dart';
import '../services/token_repository.dart';
import 'api/initial_api.dart';
import 'cache/cache_manager.dart';
import 'cache/cache_scheduler.dart';

class VolunteerService with CacheableMixin {
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

      if (resp.statusCode == 200) {
        CacheManager.markStale('current_user');
        CacheManager.markStalePattern('user_');
        CacheScheduler.forceRefreshCriticalData();
      }

      return BasicResponse(resp.statusCode ?? 0, resp.data);
    } on DioException catch (e) {
      dev.log('submitApplication error: ${e.message}');
      final status = e.response?.statusCode ?? 0;
      final data = e.response?.data;

      String errorMessage = 'Nie udało się wysłać wniosku';

      if (status == 400) {
        if (data is Map<String, dynamic>) {
          if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          } else {
            errorMessage = 'Błąd walidacji danych';
          }
        } else if (data is String) {
          errorMessage = data;
        }
      } else if (status == 409) {
        errorMessage = 'Już posiadasz aktywny wniosek o wolontariat';
      } else if (status == 401) {
        errorMessage = 'Sesja wygasła. Zaloguj się ponownie';
      } else if (status == 403) {
        errorMessage = 'Brak uprawnień do wykonania tej akcji';
      } else if (status >= 500) {
        errorMessage = 'Błąd serwera. Spróbuj ponownie później';
      }

      return BasicResponse(status, {'error': errorMessage});
    } catch (e) {
      dev.log('submitApplication unexpected error: $e');
      return BasicResponse(0, {'error': 'Nieoczekiwany błąd: ${e.toString()}'});
    }
  }

  /// Pobiera status wniosku o wolontariat
  Future<BasicResponse> getVolunteerStatus() async {
    try {
      final resp = await _api.get('/volunteer/status');
      return BasicResponse(resp.statusCode ?? 0, resp.data);
    } on DioException catch (e) {
      dev.log('getVolunteerStatus error: ${e.message}');
      final status = e.response?.statusCode ?? 0;

      String errorMessage = 'Nie udało się pobrać statusu wolontariusza';

      if (status == 404) {
        errorMessage = 'Nie znaleziono informacji o statusie wolontariusza';
      } else if (status == 401) {
        errorMessage = 'Sesja wygasła. Zaloguj się ponownie';
      }

      return BasicResponse(status, {'error': errorMessage});
    } catch (e) {
      dev.log('getVolunteerStatus unexpected error: $e');
      return BasicResponse(0, {'error': 'Nieoczekiwany błąd: ${e.toString()}'});
    }
  }

  /// Pobiera historię wniosków o wolontariat
  Future<BasicResponse> getApplicationHistory() async {
    try {
      final resp = await _api.get('/volunteer/status');
      return BasicResponse(resp.statusCode ?? 0, resp.data);
    } on DioException catch (e) {
      dev.log('getApplicationHistory error: ${e.message}');
      final status = e.response?.statusCode ?? 0;

      String errorMessage = 'Nie udało się pobrać historii wniosków';

      if (status == 404) {
        errorMessage = 'Nie znaleziono historii wniosków';
      } else if (status == 401) {
        errorMessage = 'Sesja wygasła. Zaloguj się ponownie';
      }

      return BasicResponse(status, {'error': errorMessage});
    } catch (e) {
      dev.log('getApplicationHistory unexpected error: $e');
      return BasicResponse(0, {'error': 'Nieoczekiwany błąd: ${e.toString()}'});
    }
  }
}