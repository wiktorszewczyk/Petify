import 'dart:developer' as dev;
import 'dart:math';
import 'package:dio/dio.dart';
import '../models/pet.dart';
import '../models/basic_response.dart';
import 'api/initial_api.dart';

class PetService {
  final _api = InitialApi().dio;
  static PetService? _instance;

  factory PetService() => _instance ??= PetService._();
  PetService._();

  /// Pobiera listę wszystkich zwierząt
  Future<List<Pet>> getPets() async {
    try {
      final response = await _api.get('/pets');

      if (response.statusCode == 200 && response.data is List) {
        final petsData = response.data as List;
        return petsData.map((petJson) => Pet.fromJson(petJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania zwierząt: ${e.message}');
      throw Exception('Nie udało się pobrać listy zwierząt: ${e.message}');
    }
  }

  /// Pobiera przefiltrowane zwierzęta
  Future<List<Pet>> getFilteredPets({
    bool? vaccinated,
    bool? urgent,
    bool? sterilized,
    bool? kidFriendly,
    int? minAge,
    int? maxAge,
    String? type, // CAT, DOG, OTHER
    double? userLat,
    double? userLng,
    double? radiusKm,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (vaccinated != null) queryParams['vaccinated'] = vaccinated;
      if (urgent != null) queryParams['urgent'] = urgent;
      if (sterilized != null) queryParams['sterilized'] = sterilized;
      if (kidFriendly != null) queryParams['kidFriendly'] = kidFriendly;
      if (minAge != null) queryParams['minAge'] = minAge;
      if (maxAge != null) queryParams['maxAge'] = maxAge;
      if (type != null) queryParams['type'] = type.toUpperCase();
      if (userLat != null) queryParams['userLat'] = userLat;
      if (userLng != null) queryParams['userLng'] = userLng;
      if (radiusKm != null) queryParams['radiusKm'] = radiusKm;

      final response = await _api.get('/pets/filter', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data is List) {
        final petsData = response.data as List;
        return petsData.map((petJson) => Pet.fromJson(petJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania przefiltrowanych zwierząt: ${e.message}');
      throw Exception('Nie udało się pobrać listy zwierząt: ${e.message}');
    }
  }

  /// Pobiera szczegóły zwierzęcia
  Future<Pet> getPetById(int petId) async {
    try {
      final response = await _api.get('/pets/$petId');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Pet.fromJson(response.data);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania szczegółów zwierzęcia: ${e.message}');
      throw Exception('Nie udało się pobrać szczegółów zwierzęcia: ${e.message}');
    }
  }

  /// Polub zwierzę
  Future<BasicResponse> likePet(int petId) async {
    try {
      final response = await _api.post('/pets/$petId/like');
      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas polubienia zwierzęcia: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

  /// Cofnij polubienie zwierzęcia
  Future<BasicResponse> unlikePet(int petId) async {
    try {
      final response = await _api.post('/pets/$petId/dislike');
      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas cofania polubienia: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

  /// Wesprzyj zwierzę
  Future<BasicResponse> supportPet(int petId) async {
    try {
      final response = await _api.post('/pets/$petId/support');
      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas wspierania zwierzęcia: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

  /// Pobiera polubione zwierzęta
  Future<List<Pet>> getFavoritePets() async {
    try {
      final response = await _api.get('/pets/favorites');

      if (response.statusCode == 200 && response.data is List) {
        final petsData = response.data as List;
        return petsData.map((petJson) => Pet.fromJson(petJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania polubionych zwierząt: ${e.message}');
      throw Exception('Nie udało się pobrać polubionych zwierząt: ${e.message}');
    }
  }

  /// Pobiera wspierane zwierzęta
  Future<List<Pet>> getSupportedPets() async {
    try {
      final response = await _api.get('/pets/supportedPets');

      if (response.statusCode == 200 && response.data is List) {
        final petsData = response.data as List;
        return petsData.map((petJson) => Pet.fromJson(petJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania wspieranych zwierząt: ${e.message}');
      throw Exception('Nie udało się pobrać wspieranych zwierząt: ${e.message}');
    }
  }

  /// Pobiera zdjęcie zwierzęcia
  Future<String?> getPetImage(int petId) async {
    try {
      final response = await _api.get('/pets/$petId/image');

      if (response.statusCode == 200 && response.data is String) {
        // Backend zwraca Base64 string, dodajemy prefix data URL
        return 'data:image/jpeg;base64,${response.data}';
      }

      return null;
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania zdjęcia zwierzęcia: ${e.message}');
      return null;
    }
  }

  /// Tworzy formularz adopcji
  Future<BasicResponse> createAdoptionForm({
    required int petId,
    required String motivationText,
    required String fullName,
    required String phoneNumber,
    required String address,
    required String housingType,
    required bool isHouseOwner,
    required bool hasYard,
    required bool hasOtherPets,
    String? description,
  }) async {
    try {
      final response = await _api.post('/pets/$petId/adopt', data: {
        'motivationText': motivationText,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'address': address,
        'housingType': housingType,
        'isHouseOwner': isHouseOwner,
        'hasYard': hasYard,
        'hasOtherPets': hasOtherPets,
        'description': description,
      });

      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas tworzenia formularza adopcji: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

  // Metody kompatybilności z istniejącym kodem
  Future<List<Pet>> getLikedPets() => getFavoritePets();

  // Metody do symulacji starych funkcjonalności (tymczasowo)
  Future<void> _simulateOldMethods() async {
    // Te metody były używane w starym kodzie, ale teraz używamy nowych API
  }
}