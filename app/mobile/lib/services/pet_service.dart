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
import 'cache/cache_manager.dart';

class PetService with CacheableMixin {
  final _api = InitialApi().dio;
  static PetService? _instance;

  factory PetService() => _instance ??= PetService._();
  PetService._();

  /// Oblicza odległość między dwoma punktami używając wzoru Haversine
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;

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
    final cacheKey = generateCacheKey('pets_default', {
      'vaccinated': filterPrefs.onlyVaccinated,
      'urgent': filterPrefs.onlyUrgent,
      'sterilized': filterPrefs.onlySterilized,
      'kidFriendly': filterPrefs.kidFriendly,
      'minAge': filterPrefs.minAge,
      'maxAge': filterPrefs.maxAge,
      'types': filterPrefs.animalTypes.join(','),
      'maxDistance': filterPrefs.maxDistance,
      'useCurrentLocation': filterPrefs.useCurrentLocation,
      'selectedCity': filterPrefs.selectedCity,
    });

    return cachedFetch(cacheKey, () async {
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
    }, ttl: Duration(minutes: 3));
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

    final cacheKey = generateCacheKey('pets_filtered', queryParams);

    return cachedFetch(cacheKey, () async {
      try {
        dev.log('Making request to /pets/filter with params: $queryParams');
        final response = await _api.get('/pets/filter', queryParameters: queryParams);
        dev.log('Response status: ${response.statusCode}');

        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          final swipeResponse = SwipeResponse.fromJson(response.data);
          dev.log('Parsed ${swipeResponse.pets.length} pets from SwipeResponse');

          final shelterIds = swipeResponse.pets.map((pet) => pet.shelterId).toSet();

          final shelterService = ShelterService();
          final sheltersMap = <int, Shelter>{};

          await Future.wait(shelterIds.map((shelterId) async {
            try {
              final shelter = await shelterService.getShelterById(shelterId);
              sheltersMap[shelterId] = shelter;
            } catch (e) {
              dev.log('Failed to fetch shelter $shelterId: $e');
            }
          }));

          final enrichedPets = swipeResponse.pets.map((pet) {
            final shelter = sheltersMap[pet.shelterId];

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
              shelterName: shelter?.name,
              shelterAddress: shelter?.address,
              distance: pet.distance,
            );
          }).toList();

          return enrichedPets;
        }

        throw Exception('Nieprawidłowa odpowiedź serwera');
      } on DioException catch (e) {
        dev.log('Błąd podczas pobierania przefiltrowanych zwierząt: ${e.message}');
        dev.log('Response: ${e.response?.data}');
        throw Exception('Nie udało się pobrać listy zwierząt: ${e.message}');
      }
    }, ttl: Duration(minutes: 3));
  }

  /// Pobiera zwierzęta na podstawie zapisanych filtrów użytkownika
  Future<List<Pet>> getPetsWithCustomFilters(FilterPreferences filterPrefs) async {
    final cacheKey = generateCacheKey('pets_custom', {
      'vaccinated': filterPrefs.onlyVaccinated,
      'urgent': filterPrefs.onlyUrgent,
      'sterilized': filterPrefs.onlySterilized,
      'kidFriendly': filterPrefs.kidFriendly,
      'minAge': filterPrefs.minAge,
      'maxAge': filterPrefs.maxAge,
      'types': filterPrefs.animalTypes.join(','),
      'maxDistance': filterPrefs.maxDistance,
      'useCurrentLocation': filterPrefs.useCurrentLocation,
      'selectedCity': filterPrefs.selectedCity,
    });

    return cachedFetch(cacheKey, () async {
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
    }, ttl: Duration(minutes: 3));
  }

  Future<Pet> getPetById(int petId) async {
    final cacheKey = 'pet_detail_$petId';

    return cachedFetch(cacheKey, () async {
      try {
        final response = await _api.get('/pets/$petId');

        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          final pet = Pet.fromJson(response.data);
          dev.log('getPetById - Raw pet data: ${response.data}');
          dev.log('getPetById - Pet.distance after parsing: ${pet.distance}');

          try {
            final shelter = await ShelterService().getShelterById(pet.shelterId);
            dev.log('getPetById - Shelter coordinates: lat=${shelter.latitude}, lng=${shelter.longitude}');

            double? calculatedDistance = pet.distance;
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
    }, ttl: Duration(minutes: 10));
  }

  Future<BasicResponse> likePet(int petId) async {
    try {
      final response = await _api.post('/pets/$petId/like');

      if (response.statusCode == 200) {
        CacheManager.invalidatePattern('favorites');
        CacheManager.invalidatePattern('supported');
        CacheManager.invalidatePattern('pets_'); // Invaliduj wszystkie cache zwierząt!
        dev.log('✅ LIKED PET $petId - Invalidated all pets cache. Next fetch will get fresh data from API.');
      }

      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas polubienia zwierzęcia: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

  Future<BasicResponse> unlikePet(int petId) async {
    try {
      final response = await _api.post('/pets/$petId/dislike');

      if (response.statusCode == 200) {
        CacheManager.invalidatePattern('favorites');
        CacheManager.invalidatePattern('supported');
        CacheManager.invalidatePattern('pets_');
        dev.log('Invalidated pets and favorites cache after unliking pet $petId');
      }

      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas cofania polubienia: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

  Future<BasicResponse> supportPet(int petId) async {
    try {
      final response = await _api.post('/pets/$petId/support');

      if (response.statusCode == 200) {
        CacheManager.invalidatePattern('supported');
        dev.log('Invalidated supported pets cache after supporting pet $petId');
      }

      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      dev.log('Błąd podczas wspierania zwierzęcia: ${e.message}');
      return BasicResponse(e.response?.statusCode ?? 0, {'error': e.message});
    }
  }

  Future<List<Pet>> getFavoritePets() async {
    const cacheKey = 'favorites_pets';

    return cachedFetch(cacheKey, () async {
      try {
        final response = await _api.get('/pets/favorites');

        if (response.statusCode == 200 && response.data is List) {
          final petsData = response.data as List;
          List<Pet> pets = petsData.map((petJson) => Pet.fromJson(petJson)).toList();

          double? userLat;
          double? userLng;
          try {
            final position = await LocationService().getCurrentLocation().timeout(Duration(seconds: 2));
            if (position != null) {
              userLat = position.latitude;
              userLng = position.longitude;
              dev.log('getFavoritePets - User position: lat=$userLat, lng=$userLng');
            }
          } catch (e) {
            dev.log('getFavoritePets - Location fetch timeout or failed, continuing without distance: $e');
          }

          final shelterIds = pets.map((pet) => pet.shelterId).toSet();
          final shelterService = ShelterService();
          final sheltersMap = <int, Shelter>{};

          try {
            await Future.wait(
                shelterIds.map((shelterId) async {
                  try {
                    final shelter = await shelterService.getShelterById(shelterId).timeout(Duration(seconds: 3));
                    sheltersMap[shelterId] = shelter;
                  } catch (e) {
                    dev.log('Failed to fetch shelter $shelterId: $e');
                  }
                })
            ).timeout(Duration(seconds: 5));
          } catch (e) {
            dev.log('Shelter batch fetch timeout: $e');
          }

          final enrichedPets = pets.map((pet) {
            final shelter = sheltersMap[pet.shelterId];

            double? calculatedDistance = pet.distance;
            if (calculatedDistance == null && userLat != null && userLng != null && shelter != null) {
              if (shelter.latitude != null && shelter.longitude != null) {
                calculatedDistance = _calculateDistance(
                    userLat, userLng,
                    shelter.latitude!, shelter.longitude!
                );
              }
            }

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
              shelterName: shelter?.name,
              shelterAddress: shelter?.address,
              distance: calculatedDistance,
            );
          }).toList();

          return enrichedPets;
        }

        throw Exception('Nieprawidłowa odpowiedź serwera');
      } on DioException catch (e) {
        dev.log('Błąd podczas pobierania polubionych zwierząt: ${e.message}');
        throw Exception('Nie udało się pobrać polubionych zwierząt: ${e.message}');
      }
    }, ttl: Duration(minutes: 5));
  }

  Future<List<Pet>> getSupportedPets() async {
    try {
      final response = await _api.get('/pets/supportedPets');

      if (response.statusCode == 200 && response.data is List) {
        final petsData = response.data as List;
        List<Pet> pets = petsData.map((petJson) => Pet.fromJson(petJson)).toList();

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

        List<Pet> enrichedPets = await Future.wait(pets.map((pet) async {
          try {
            final shelter = await ShelterService().getShelterById(pet.shelterId);

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
            return enrichedPet;
          } catch (e) {
            dev.log('Failed to fetch shelter info for supported pet ${pet.id}: $e');
            return pet;
          }
        }));

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