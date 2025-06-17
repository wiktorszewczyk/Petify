import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache/cache_manager.dart';

class LocationService with CacheableMixin {
  static LocationService? _instance;

  factory LocationService() => _instance ??= LocationService._();
  LocationService._();

  Future<Position?> getCurrentLocation() async {
    const cacheKey = 'current_location';

    return cachedFetch(cacheKey, () async {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5), // Skróć timeout
        );
      } catch (e) {
        return null;
      }
    }, ttl: Duration(minutes: 15)); // Cache lokalizacji na 15 minut
  }

  Future<Position?> getCityCoordinates(String cityName) async {
    final cacheKey = 'city_coords_$cityName';

    return cachedFetch(cacheKey, () async {
      try {
        List<Location> locations = await locationFromAddress('$cityName, Polska');
        if (locations.isNotEmpty) {
          return Position(
            longitude: locations.first.longitude,
            latitude: locations.first.latitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            floor: null,
            isMocked: false,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      } catch (e) {
        print('Błąd podczas wyszukiwania miasta: $e');
      }
      return null;
    }, ttl: Duration(hours: 24)); // Cache koordynatów miast na 24h - bardzo rzadko się zmieniają
  }

  Future<void> saveLocationPreferences({
    required bool useCurrentLocation,
    required double? latitude,
    required double? longitude,
    String? cityName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_current_location', useCurrentLocation);

    if (latitude != null && longitude != null) {
      await prefs.setDouble('saved_latitude', latitude);
      await prefs.setDouble('saved_longitude', longitude);
    }

    if (cityName != null) {
      await prefs.setString('saved_city', cityName);
    }
  }

  Future<Map<String, dynamic>> getLocationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'use_current_location': prefs.getBool('use_current_location') ?? true,
      'latitude': prefs.getDouble('saved_latitude'),
      'longitude': prefs.getDouble('saved_longitude'),
      'city_name': prefs.getString('saved_city'),
    };
  }

  /// Oblicza odległość między dwoma punktami w kilometrach
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0; // na km
  }

  /// Formatuje odległość do wyświetlenia
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }
}