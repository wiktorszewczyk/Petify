import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/adoption.dart';
import 'api/initial_api.dart';
import 'pet_service.dart';

class ApplicationService {
  final _api = InitialApi().dio;
  final _petService = PetService();
  static ApplicationService? _instance;
  factory ApplicationService() => _instance ??= ApplicationService._();
  ApplicationService._();

  Future<List<AdoptionResponse>> getMyAdoptionApplications() async {
    try {
      dev.log('ApplicationService: Pobieranie wniosków adopcyjnych przez PetService');

      final adoptionsData = await _petService.getMyAdoptions();

      final adoptions = <AdoptionResponse>[];
      for (int i = 0; i < adoptionsData.length; i++) {
        try {
          final adoption = AdoptionResponse.fromJson(adoptionsData[i]);
          adoptions.add(adoption);
        } catch (e) {
          dev.log('ApplicationService: Błąd podczas parsowania wniosku $i: $e');
          dev.log('ApplicationService: Problematyczne dane: ${adoptionsData[i]}');
        }
      }

      dev.log('ApplicationService: Zwracam ${adoptions.length} wniosków adopcyjnych');
      return adoptions;

    } catch (e) {
      dev.log('ApplicationService: Błąd w getMyAdoptionApplications: $e');
      if (e.toString().contains('400')) {
        return [];
      }
      throw Exception('Nie udało się pobrać wniosków adopcyjnych: $e');
    }
  }

  Future<void> cancelAdoptionApplication(int adoptionId) async {
    try {
      final response = await _api.patch('/adoptions/$adoptionId/cancel');

      if (response.statusCode != 200) {
        throw Exception('Nieprawidłowa odpowiedź serwera');
      }
    } on DioException catch (e) {
      dev.log('Błąd podczas anulowania wniosku adopcyjnego: ${e.message}');

      if (e.response?.statusCode == 403) {
        throw Exception('Brak uprawnień do anulowania tego wniosku');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Nie znaleziono wniosku');
      }

      throw Exception('Nie udało się anulować wniosku: ${e.message}');
    }
  }

  Future<AdoptionResponse> getAdoptionDetails(int adoptionId) async {
    try {
      final response = await _api.get('/adoptions/$adoptionId');

      if (response.statusCode == 200) {
        return AdoptionResponse.fromJson(response.data);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania szczegółów wniosku: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('Nie znaleziono wniosku');
      }

      throw Exception('Nie udało się pobrać szczegółów wniosku: ${e.message}');
    }
  }
}