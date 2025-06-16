import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:dio/dio.dart';
import '../models/filter_preferences.dart';
import '../models/pet.dart';
import '../models/basic_response.dart';
import '../models/swipe_response.dart';
import '../models/shelter.dart';
import '../services/filter_preferences_service.dart';
import '../services/location_service.dart';
import '../services/shelter_service.dart';
import 'api/initial_api.dart';

class PetService {
  final _api = InitialApi().dio;
  static PetService? _instance;

  factory PetService() => _instance ??= PetService._();
  PetService._();

  /// Oblicza odległość między dwoma punktami używając wzoru Haversine
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Promień Ziemi w kilometrach

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

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
    int? cursor,
    int? limit,
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
      if (cursor != null) queryParams['cursor'] = cursor;
      if (limit != null) queryParams['limit'] = limit;

      dev.log('Making request to /pets/filter with params: $queryParams');
      final response = await _api.get('/pets/filter', queryParameters: queryParams);
      dev.log('Response status: ${response.statusCode}');
      dev.log('Response data type: ${response.data.runtimeType}');
      dev.log('Response data: ${response.data}');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final swipeResponse = SwipeResponse.fromJson(response.data);
        dev.log('Parsed ${swipeResponse.pets.length} pets from SwipeResponse');

        // Wzbogać dane o informacje o schronisku dla każdego zwierzaka
        List<Pet> enrichedPets = [];
        for (Pet pet in swipeResponse.pets) {
          try {
            final shelter = await ShelterService().getShelterById(pet.shelterId);

            // Używaj odległości z backendu
            final distanceFromBackend = pet.distance;
            if (distanceFromBackend != null) {
              dev.log('Backend returned distance for pet ${pet.name}: ${distanceFromBackend.toStringAsFixed(1)} km');
            } else {
              dev.log('Backend did not return distance for pet ${pet.name}');
            }

            // Stwórz nowy Pet z informacjami o schronisku i obliczoną odległością
            final enrichedPet = Pet(
              id: pet.id,
              name: pet.name,
              type: pet.type,
              breed: pet.breed,
              age: pet.age,
              archived: pet.archived,
              description: pet.description,
              shelterId: pet.shelterId,
              gender: pet.gender,
              size: pet.size,
              vaccinated: pet.vaccinated,
              urgent: pet.urgent,
              sterilized: pet.sterilized,
              kidFriendly: pet.kidFriendly,
              imageUrl: pet.imageUrl,
              images: pet.images,
              shelterName: shelter.name,
              shelterAddress: shelter.address,
              distance: distanceFromBackend, // Używamy odległości z backendu
            );
            enrichedPets.add(enrichedPet);
          } catch (e) {
            dev.log('Failed to fetch shelter info for pet ${pet.id}: $e');
            // Dodaj zwierzaka bez informacji o schronisku
            enrichedPets.add(pet);
          }
        }

        return enrichedPets;
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania przefiltrowanych zwierząt: ${e.message}');
      dev.log('Response: ${e.response?.data}');
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
        final pet = Pet.fromJson(response.data);
        dev.log('getPetById - Raw pet data: ${response.data}');
        dev.log('getPetById - Pet.distance after parsing: ${pet.distance}');

        // Wzbogać dane o informacje o schronisku
        try {
          final shelter = await ShelterService().getShelterById(pet.shelterId);
          dev.log('getPetById - Shelter coordinates: lat=${shelter.latitude}, lng=${shelter.longitude}');

          // Spróbuj pobrać lokalizację użytkownika do obliczenia odległości
          // (backend w getPetById nie zwraca distance, więc obliczamy po stronie mobilnej)
          double? calculatedDistance = pet.distance; // Sprawdź czy backend zwrócił
          dev.log('getPetById - Initial distance from backend: $calculatedDistance');

          if (calculatedDistance == null) {
            try {
              dev.log('getPetById - Trying to get user location...');
              final position = await LocationService().getCurrentLocation();
              dev.log('getPetById - User position: lat=${position?.latitude}, lng=${position?.longitude}');

              if (position != null && shelter.latitude != null && shelter.longitude != null) {
                calculatedDistance = _calculateDistance(
                    position.latitude, position.longitude,
                    shelter.latitude!, shelter.longitude!
                );
                dev.log('getPetById - Calculated distance for pet ${pet.name}: ${calculatedDistance?.toStringAsFixed(1)} km');
              } else {
                dev.log('getPetById - Cannot calculate distance: position=$position, shelter.lat=${shelter.latitude}, shelter.lng=${shelter.longitude}');
              }
            } catch (e) {
              dev.log('getPetById - Failed to get user location: $e');
            }
          } else {
            dev.log('getPetById - Using distance from backend: ${calculatedDistance.toStringAsFixed(1)} km');
          }

          dev.log('getPetById - Final calculated distance: $calculatedDistance');

          return Pet(
            id: pet.id,
            name: pet.name,
            type: pet.type,
            breed: pet.breed,
            age: pet.age,
            archived: pet.archived,
            description: pet.description,
            shelterId: pet.shelterId,
            gender: pet.gender,
            size: pet.size,
            vaccinated: pet.vaccinated,
            urgent: pet.urgent,
            sterilized: pet.sterilized,
            kidFriendly: pet.kidFriendly,
            imageUrl: pet.imageUrl,
            images: pet.images,
            shelterName: shelter.name,
            shelterAddress: shelter.address,
            distance: calculatedDistance,
          );
        } catch (e) {
          dev.log('Failed to fetch shelter info for pet $petId: $e');
          return pet;
        }
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
        List<Pet> pets = petsData.map((petJson) => Pet.fromJson(petJson)).toList();

        // Pobierz lokalizację użytkownika raz na początku
        double? userLat;
        double? userLng;
        try {
          final position = await LocationService().getCurrentLocation();
          if (position != null) {
            userLat = position.latitude;
            userLng = position.longitude;
            dev.log('getFavoritePets - User position: lat=$userLat, lng=$userLng');
          } else {
            dev.log('getFavoritePets - No user position available');
          }
        } catch (e) {
          dev.log('getFavoritePets - Failed to get user location: $e');
        }

        // Wzbogać dane o informacje o schronisku dla każdego zwierzaka
        List<Pet> enrichedPets = [];
        for (Pet pet in pets) {
          try {
            final shelter = await ShelterService().getShelterById(pet.shelterId);

            // Oblicz odległość jeśli backend jej nie zwrócił
            double? calculatedDistance = pet.distance;
            if (calculatedDistance == null && userLat != null && userLng != null) {
              if (shelter.latitude != null && shelter.longitude != null) {
                calculatedDistance = _calculateDistance(
                    userLat, userLng,
                    shelter.latitude!, shelter.longitude!
                );
                dev.log('getFavoritePets - Calculated distance for pet ${pet.name}: ${calculatedDistance?.toStringAsFixed(1)} km');
              } else {
                dev.log('getFavoritePets - No shelter coordinates for pet ${pet.name}');
              }
            } else if (calculatedDistance != null) {
              dev.log('getFavoritePets - Using backend distance for pet ${pet.name}: ${calculatedDistance.toStringAsFixed(1)} km');
            } else {
              dev.log('getFavoritePets - No user location for distance calculation for pet ${pet.name}');
            }

            final enrichedPet = Pet(
              id: pet.id,
              name: pet.name,
              type: pet.type,
              breed: pet.breed,
              age: pet.age,
              archived: pet.archived,
              description: pet.description,
              shelterId: pet.shelterId,
              gender: pet.gender,
              size: pet.size,
              vaccinated: pet.vaccinated,
              urgent: pet.urgent,
              sterilized: pet.sterilized,
              kidFriendly: pet.kidFriendly,
              imageUrl: pet.imageUrl,
              images: pet.images,
              shelterName: shelter.name,
              shelterAddress: shelter.address,
              distance: calculatedDistance,
            );
            enrichedPets.add(enrichedPet);
          } catch (e) {
            dev.log('Failed to fetch shelter info for favorite pet ${pet.id}: $e');
            enrichedPets.add(pet);
          }
        }

        return enrichedPets;
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
        List<Pet> pets = petsData.map((petJson) => Pet.fromJson(petJson)).toList();

        // Pobierz lokalizację użytkownika raz na początku
        double? userLat;
        double? userLng;
        try {
          final position = await LocationService().getCurrentLocation();
          if (position != null) {
            userLat = position.latitude;
            userLng = position.longitude;
            dev.log('getSupportedPets - User position: lat=$userLat, lng=$userLng');
          } else {
            dev.log('getSupportedPets - No user position available');
          }
        } catch (e) {
          dev.log('getSupportedPets - Failed to get user location: $e');
        }

        // Wzbogać dane o informacje o schronisku dla każdego zwierzaka
        List<Pet> enrichedPets = [];
        for (Pet pet in pets) {
          try {
            final shelter = await ShelterService().getShelterById(pet.shelterId);

            // Oblicz odległość jeśli backend jej nie zwrócił
            double? calculatedDistance = pet.distance;
            if (calculatedDistance == null && userLat != null && userLng != null) {
              if (shelter.latitude != null && shelter.longitude != null) {
                calculatedDistance = _calculateDistance(
                    userLat, userLng,
                    shelter.latitude!, shelter.longitude!
                );
                dev.log('getSupportedPets - Calculated distance for pet ${pet.name}: ${calculatedDistance?.toStringAsFixed(1)} km');
              } else {
                dev.log('getSupportedPets - No shelter coordinates for pet ${pet.name}');
              }
            } else if (calculatedDistance != null) {
              dev.log('getSupportedPets - Using backend distance for pet ${pet.name}: ${calculatedDistance.toStringAsFixed(1)} km');
            } else {
              dev.log('getSupportedPets - No user location for distance calculation for pet ${pet.name}');
            }

            final enrichedPet = Pet(
              id: pet.id,
              name: pet.name,
              type: pet.type,
              breed: pet.breed,
              age: pet.age,
              archived: pet.archived,
              description: pet.description,
              shelterId: pet.shelterId,
              gender: pet.gender,
              size: pet.size,
              vaccinated: pet.vaccinated,
              urgent: pet.urgent,
              sterilized: pet.sterilized,
              kidFriendly: pet.kidFriendly,
              imageUrl: pet.imageUrl,
              images: pet.images,
              shelterName: shelter.name,
              shelterAddress: shelter.address,
              distance: calculatedDistance,
            );
            enrichedPets.add(enrichedPet);
          } catch (e) {
            dev.log('Failed to fetch shelter info for supported pet ${pet.id}: $e');
            enrichedPets.add(pet);
          }
        }

        return enrichedPets;
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

  Future<List<Map<String, dynamic>>> getMyAdoptions() async {
    try {
      final response = await _api.get('/pets/my-adoptions');

      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      throw Exception('Nie udało się pobrać wniosków adopcyjnych: ${e.message}');
    }
  }
}