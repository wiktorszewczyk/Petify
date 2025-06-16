import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/event.dart';
import '../models/shelter_post.dart';
import 'api/initial_api.dart';

class FeedService {
  final _api = InitialApi().dio;
  static FeedService? _instance;
  factory FeedService() => _instance ??= FeedService._();
  FeedService._();

  /// Pobiera najbliższe wydarzenia w ciągu określonej liczby dni
  Future<List<Event>> getIncomingEvents(int days) async {
    try {
      final response = await _api.get('/events/incoming/$days');

      if (response.statusCode == 200 && response.data is List) {
        final eventsData = response.data as List;
        return eventsData.map((eventJson) => Event.fromBackendJson(eventJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania wydarzeń: ${e.message}');
      throw Exception('Nie udało się pobrać wydarzeń: ${e.message}');
    }
  }

  /// Wyszukuje wydarzenia w ciągu określonej liczby dni
  Future<List<Event>> searchIncomingEvents(int days, String searchQuery) async {
    try {
      final response = await _api.get(
        '/events/incoming/$days/search',
        queryParameters: {'content': searchQuery},
      );

      if (response.statusCode == 200 && response.data is List) {
        final eventsData = response.data as List;
        return eventsData.map((eventJson) => Event.fromBackendJson(eventJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas wyszukiwania wydarzeń: ${e.message}');
      throw Exception('Nie udało się wyszukać wydarzeń: ${e.message}');
    }
  }

  /// Pobiera szczegóły konkretnego wydarzenia
  Future<Event> getEventById(int eventId) async {
    try {
      final response = await _api.get('/events/$eventId');

      if (response.statusCode == 200) {
        return Event.fromBackendJson(response.data);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania wydarzenia: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Nie znaleziono wydarzenia');
      }
      throw Exception('Nie udało się pobrać wydarzenia: ${e.message}');
    }
  }

  /// Dołącza do wydarzenia
  Future<void> joinEvent(int eventId) async {
    try {
      final response = await _api.post('/events/$eventId/participants');

      if (response.statusCode != 201) {
        throw Exception('Nieprawidłowa odpowiedź serwera');
      }
    } on DioException catch (e) {
      dev.log('Błąd podczas dołączania do wydarzenia: ${e.message}');

      if (e.response?.statusCode == 409) {
        throw Exception('Już bierzesz udział w tym wydarzeniu');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Wydarzenie jest pełne lub rejestracja zakończona');
      }

      throw Exception('Nie udało się dołączyć do wydarzenia: ${e.message}');
    }
  }

  /// Opuszcza wydarzenie
  Future<void> leaveEvent(int eventId) async {
    try {
      final response = await _api.delete('/events/$eventId/participants');

      if (response.statusCode != 204) {
        throw Exception('Nieprawidłowa odpowiedź serwera');
      }
    } on DioException catch (e) {
      dev.log('Błąd podczas opuszczania wydarzenia: ${e.message}');
      throw Exception('Nie udało się opuścić wydarzenia: ${e.message}');
    }
  }

  /// Pobiera najnowsze posty w ciągu określonej liczby dni
  Future<List<ShelterPost>> getRecentPosts(int days) async {
    try {
      final response = await _api.get('/posts/recent/$days');

      if (response.statusCode == 200 && response.data is List) {
        final postsData = response.data as List;
        return postsData.map((postJson) => ShelterPost.fromBackendJson(postJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania postów: ${e.message}');
      throw Exception('Nie udało się pobrać ogłoszeń: ${e.message}');
    }
  }

  /// Wyszukuje posty w ciągu określonej liczby dni
  Future<List<ShelterPost>> searchRecentPosts(int days, String searchQuery) async {
    try {
      final response = await _api.get(
        '/posts/recent/$days/search',
        queryParameters: {'content': searchQuery},
      );

      if (response.statusCode == 200 && response.data is List) {
        final postsData = response.data as List;
        return postsData.map((postJson) => ShelterPost.fromBackendJson(postJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas wyszukiwania postów: ${e.message}');
      throw Exception('Nie udało się wyszukać ogłoszeń: ${e.message}');
    }
  }

  /// Pobiera szczegóły konkretnego postu
  Future<ShelterPost> getPostById(int postId) async {
    try {
      final response = await _api.get('/posts/$postId');

      if (response.statusCode == 200) {
        return ShelterPost.fromBackendJson(response.data);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania postu: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Nie znaleziono ogłoszenia');
      }
      throw Exception('Nie udało się pobrać ogłoszenia: ${e.message}');
    }
  }

  /// Pobiera liczba uczestników wydarzenia
  Future<int> getEventParticipantsCount(int eventId) async {
    try {
      final response = await _api.get('/events/$eventId/participants/count');

      if (response.statusCode == 200) {
        return response.data as int;
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania liczby uczestników: ${e.message}');
      return 0; // Fallback value
    }
  }
}