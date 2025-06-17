import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/shelter.dart';
import '../models/pet.dart';
import '../models/basic_response.dart';
import 'api/initial_api.dart';

class ShelterService {
  final _api = InitialApi().dio;
  static ShelterService? _instance;

  factory ShelterService() => _instance ??= ShelterService._();
  ShelterService._();

  /// Pobiera listę wszystkich schronisk
  Future<List<Shelter>> getShelters() async {
    try {
      final response = await _api.get('/shelters');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final sheltersData = data['content'] as List? ?? [];
        List<Shelter> shelters = [];

        for (var shelterJson in sheltersData) {
          var shelter = Shelter.fromJson(shelterJson);

          shelter = await _enrichShelterData(shelter);
          shelters.add(shelter);
        }

        return shelters;
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania schronisk: ${e.message}');
      throw Exception('Nie udało się pobrać listy schronisk: ${e.message}');
    }
  }

  /// Pobiera szczegóły schroniska
  Future<Shelter> getShelterById(int shelterId) async {
    try {
      final response = await _api.get('/shelters/$shelterId');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        var shelter = Shelter.fromJson(response.data);
        return await _enrichShelterData(shelter);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania szczegółów schroniska: ${e.message}');
      throw Exception('Nie udało się pobrać szczegółów schroniska: ${e.message}');
    }
  }

  /// Pobiera zwierzęta z konkretnego schroniska
  Future<List<Pet>> getShelterPets(int shelterId) async {
    try {
      final response = await _api.get('/shelters/$shelterId/pets');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final petsData = data['content'] as List? ?? [];
        return petsData.map((petJson) => Pet.fromJson(petJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania zwierząt ze schroniska: ${e.message}');
      throw Exception('Nie udało się pobrać zwierząt ze schroniska: ${e.message}');
    }
  }

  /// Pobiera trasę do schroniska
  Future<String?> getRouteToShelter({
    required int shelterId,
    required double userLatitude,
    required double userLongitude,
  }) async {
    try {
      final response = await _api.get('/shelters/$shelterId/route', queryParameters: {
        'latitude': userLatitude,
        'longitude': userLongitude,
      });

      if (response.statusCode == 200) {
        return response.data.toString();
      }

      return null;
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania trasy: ${e.message}');
      return null;
    }
  }

  /// Wzbogaca dane schroniska o dodatkowe informacje
  Future<Shelter> _enrichShelterData(Shelter shelter) async {
    try {
      final petsCount = await _getPetsCount(shelter.id);

      return shelter.copyWith(petsCount: petsCount);

    } catch (e) {
      dev.log('Błąd podczas wzbogacania danych schroniska: $e');
      return shelter;
    }
  }

  /// Pobiera liczbę zwierząt w schronisku
  Future<int> _getPetsCount(int shelterId) async {
    try {
      final pets = await getShelterPets(shelterId);
      return pets.length;
    } catch (e) {
      return 0;
    }
  }

  /// Pobiera główną zbiórkę schroniska (MAIN fundraiser)
  Future<Map<String, dynamic>?> getShelterMainFundraiser(int shelterId) async {
    try {
      final response = await _api.get('/fundraisers/shelter/$shelterId/main');

      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }

      return null;
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania głównej zbiórki schroniska: ${e.message}');
      return null;
    }
  }

  /// Pobiera wszystkie zbiórki schroniska
  Future<List<Map<String, dynamic>>> getShelterFundraisers(int shelterId) async {
    try {
      final response = await _api.get('/fundraisers/shelter/$shelterId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final content = data['content'] as List? ?? [];
        return content.cast<Map<String, dynamic>>();
      }

      return [];
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania zbiórek schroniska: ${e.message}');
      return [];
    }
  }

  /// Symulacja wsparcia schroniska (tymczasowo)
  Future<bool> donateShelter(String shelterId, double amount) async {
    try {
      // TODO: Implementacja rzeczywistego API dla donacji
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      dev.log('Błąd podczas wsparcia schroniska: $e');
      return false;
    }
  }
}