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

      if (response.statusCode == 200 && response.data is List) {
        final sheltersData = response.data as List;
        List<Shelter> shelters = [];

        for (var shelterJson in sheltersData) {
          var shelter = Shelter.fromJson(shelterJson);

          // Dodaj dodatkowe informacje (liczba zwierząt, miasto itp.)
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

      if (response.statusCode == 200 && response.data is List) {
        final petsData = response.data as List;
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
      // Pobierz liczbę zwierząt w schronisku
      final petsCount = await _getPetsCount(shelter.id);

      // Generuj dodatkowe dane dla UI (tymczasowo)
      final enrichedData = _generateAdditionalShelterData(shelter);

      return shelter.copyWith(
        petsCount: petsCount,
        volunteersCount: enrichedData['volunteersCount'],
        needs: enrichedData['needs'],
        email: enrichedData['email'],
        website: enrichedData['website'],
        isUrgent: enrichedData['isUrgent'],
        donationGoal: enrichedData['donationGoal'],
        donationCurrent: enrichedData['donationCurrent'],
        city: enrichedData['city'],
      );
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

  /// Generuje dodatkowe dane dla schroniska (tymczasowo, dopóki backend ich nie obsługuje)
  Map<String, dynamic> _generateAdditionalShelterData(Shelter shelter) {
    // Tymczasowe dane - można je zastąpić prawdziwymi z backendu gdy będą dostępne
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    final needsList = [
      'Karma sucha i mokra dla psów i kotów',
      'Koce, poduszki i legowiska',
      'Środki czystości',
      'Zabawki dla zwierząt',
      'Smycze i obroże',
      'Leki i środki medyczne',
      'Kuwety i żwirek dla kotów',
      'Wsparcie finansowe na leczenie weterynaryjne',
    ];

    // Wybierz losowe potrzeby
    final shuffledNeeds = List<String>.from(needsList)..shuffle();
    final selectedNeeds = shuffledNeeds.take(3 + (random % 3)).toList();

    // Wyciągnij miasto z adresu
    String? city;
    if (shelter.address != null) {
      final addressParts = shelter.address!.split(',');
      if (addressParts.length > 1) {
        city = addressParts.last.trim();
      }
    }

    return {
      'volunteersCount': 10 + (random % 20),
      'needs': selectedNeeds,
      'email': '${shelter.name.toLowerCase().replaceAll(' ', '')}@schronisko.pl',
      'website': 'www.${shelter.name.toLowerCase().replaceAll(' ', '')}.pl',
      'isUrgent': random % 10 < 3, // 30% szans na pilność
      'donationGoal': (5 + (random % 10)) * 1000.0, // 5000-15000
      'donationCurrent': (random % 5) * 1000.0, // 0-5000
      'city': city ?? 'Nieznane',
    };
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