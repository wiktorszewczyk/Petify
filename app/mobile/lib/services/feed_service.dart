import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/event.dart';
import '../models/event_participant.dart';
import '../models/shelter_post.dart';
import 'api/initial_api.dart';
import 'image_service.dart';
import 'cache/cache_manager.dart';

class FeedService with CacheableMixin {
  final _api = InitialApi().dio;
  static FeedService? _instance;
  factory FeedService() => _instance ??= FeedService._();
  FeedService._();

  /// Pobiera najbliższe wydarzenia w ciągu określonej liczby dni
  Future<List<Event>> getIncomingEvents(int days) async {
    final cacheKey = 'incoming_events_$days';

    return cachedFetch(cacheKey, () async {
      try {
        final response = await _api.get('/events/incoming/$days');

        if (response.statusCode == 200 && response.data is List) {
          final eventsData = response.data as List;
          final imageService = ImageService();
          return Future.wait(eventsData.map((eventJson) async {
            var event = Event.fromBackendJson(eventJson);
            if (event.mainImageId != null) {
              try {
                final img = await imageService.getImageById(event.mainImageId!);
                event = event.copyWith(imageUrl: img.imageUrl);
              } catch (_) {}
            }
            return event;
          }));
        }

        throw Exception('Nieprawidłowa odpowiedź serwera');
      } on DioException catch (e) {
        dev.log('Błąd podczas pobierania wydarzeń: ${e.message}');
        throw Exception('Nie udało się pobrać wydarzeń: ${e.message}');
      }
    }, ttl: Duration(minutes: 10));
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
        final imageService = ImageService();
        return Future.wait(eventsData.map((eventJson) async {
          var event = Event.fromBackendJson(eventJson);
          if (event.mainImageId != null) {
            try {
              final img = await imageService.getImageById(event.mainImageId!);
              event = event.copyWith(imageUrl: img.imageUrl);
            } catch (_) {}
          }
          return event;
        }));
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
        var event = Event.fromBackendJson(response.data);
        if (event.mainImageId != null) {
          try {
            final img = await ImageService().getImageById(event.mainImageId!);
            event = event.copyWith(imageUrl: img.imageUrl);
          } catch (_) {}
        }
        return event;
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
        final imageService = ImageService();
        return Future.wait(postsData.map((postJson) async {
          var post = ShelterPost.fromBackendJson(postJson);
          if (post.mainImageId != null) {
            try {
              final img = await imageService.getImageById(post.mainImageId!);
              post = post.copyWith(imageUrl: img.imageUrl);
            } catch (_) {}
          }
          return post;
        }));
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
        final imageService = ImageService();
        return Future.wait(postsData.map((postJson) async {
          var post = ShelterPost.fromBackendJson(postJson);
          if (post.mainImageId != null) {
            try {
              final img = await imageService.getImageById(post.mainImageId!);
              post = post.copyWith(imageUrl: img.imageUrl);
            } catch (_) {}
          }
          return post;
        }));
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
        var post = ShelterPost.fromBackendJson(response.data);
        if (post.mainImageId != null) {
          try {
            final img = await ImageService().getImageById(post.mainImageId!);
            post = post.copyWith(imageUrl: img.imageUrl);
          } catch (_) {}
        }
        return post;
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
      return 0;
    }
  }

  Future<List<EventParticipant>> getEventParticipants(int eventId) async {
    try {
      final response = await _api.get('/events/$eventId/participants');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((j) => EventParticipant.fromJson(j))
            .toList();
      }
      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania uczestników: ${e.message}');
      rethrow;
    }
  }
}