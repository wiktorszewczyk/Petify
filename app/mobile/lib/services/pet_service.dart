import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/filter_preferences.dart';
import '../models/pet.dart';
import '../models/basic_response.dart';
import '../services/filter_preferences_service.dart';
import '../services/location_service.dart';
import 'api/initial_api.dart';

class PetService {
  final _api = InitialApi().dio;
  static PetService? _instance;

  factory PetService() => _instance ??= PetService._();
  PetService._();

  /// Pobiera zwierzęta z domyślnymi filtrami
  Future<List<Pet>> getPetsWithDefaultFilters() async {
    final filterPrefs = await FilterPreferencesService().getFilterPreferences();
    final locationService = LocationService();

    double? userLat;
    double? userLng;

    if (filterPrefs.useCurrentLocation) {
      final position = await locationService.getCurrentLocation();
      if (position != null) {
        userLat = position.latitude;
        userLng = position.longitude;
      }
    } else if (filterPrefs.selectedCity != null) {
      final position = await locationService.getCityCoordinates(filterPrefs.selectedCity!);
      if (position != null) {
        userLat = position.latitude;
        userLng = position.longitude;
      }
    }

    return getFilteredPets(
      vaccinated: filterPrefs.onlyVaccinated ? true : null,
      urgent: filterPrefs.onlyUrgent ? true : null,
      sterilized: filterPrefs.onlySterilized ? true : null,
      kidFriendly: filterPrefs.kidFriendly ? true : null,
      minAge: filterPrefs.minAge,
      maxAge: filterPrefs.maxAge,
      type: _mapAnimalTypesToBackend(filterPrefs.animalTypes),
      userLat: userLat,
      userLng: userLng,
      radiusKm: filterPrefs.maxDistance,
    );
  }

  String? _mapAnimalTypesToBackend(Set<String> types) {
    if (types.isEmpty || types.length >= 3) {
      return null;
    }

    if (types.length == 1) {
      final type = types.first;
      switch (type) {
        case 'Psy':
          return 'DOG';
        case 'Koty':
          return 'CAT';
        case 'Inne':
          return 'OTHER';
        default:
          return null;
      }
    }

    return null;
  }

  /// Pobiera listę wszystkich zwierząt (używana tylko dla kompatybilności)
  @Deprecated('Użyj getPetsWithDefaultFilters() lub getFilteredPets()')
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

  /// Pobiera przefiltrowane zwierzęta z backendu
  Future<List<Pet>> getFilteredPets({
    bool? vaccinated,
    bool? urgent,
    bool? sterilized,
    bool? kidFriendly,
    int? minAge,
    int? maxAge,
    String? type, // DOG, CAT, OTHER
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
      if (type != null) queryParams['type'] = type;
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

  /// Pobiera zwierzęta na podstawie zapisanych filtrów użytkownika
  Future<List<Pet>> getPetsWithCustomFilters(FilterPreferences filterPrefs) async {
    final locationService = LocationService();

    double? userLat;
    double? userLng;

    if (filterPrefs.useCurrentLocation) {
      final position = await locationService.getCurrentLocation();
      if (position != null) {
        userLat = position.latitude;
        userLng = position.longitude;
      }
    } else if (filterPrefs.selectedCity != null) {
      final position = await locationService.getCityCoordinates(filterPrefs.selectedCity!);
      if (position != null) {
        userLat = position.latitude;
        userLng = position.longitude;
      }
    }

    return getFilteredPets(
      vaccinated: filterPrefs.onlyVaccinated ? true : null,
      urgent: filterPrefs.onlyUrgent ? true : null,
      sterilized: filterPrefs.onlySterilized ? true : null,
      kidFriendly: filterPrefs.kidFriendly ? true : null,
      minAge: filterPrefs.minAge,
      maxAge: filterPrefs.maxAge,
      type: _mapAnimalTypesToBackend(filterPrefs.animalTypes),
      userLat: userLat,
      userLng: userLng,
      radiusKm: filterPrefs.maxDistance, // null = bez ograniczeń
    );
  }

  // Reszta metod bez zmian...
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

  Future<BasicResponse> likePet(int petId) async {
    try {
      final response = await _api.post('/pets/$petId/like');
      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas polubienia zwierzęcia: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

  Future<BasicResponse> unlikePet(int petId) async {
    try {
      final response = await _api.post('/pets/$petId/dislike');
      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas cofania polubienia: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

  Future<BasicResponse> supportPet(int petId) async {
    try {
      final response = await _api.post('/pets/$petId/support');
      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas wspierania zwierzęcia: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

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

  Future<String?> getPetImage(int petId) async {
    try {
      final response = await _api.get('/pets/$petId/image');

      if (response.statusCode == 200 && response.data is String) {
        return 'data:image/jpeg;base64,${response.data}';
      }

      return null;
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania zdjęcia zwierzęcia: ${e.message}');
      return null;
    }
  }

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

  Future<List<Pet>> getLikedPets() => getFavoritePets();
}