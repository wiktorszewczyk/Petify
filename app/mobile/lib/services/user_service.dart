import 'dart:developer' as dev;
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:mobile/services/token_repository.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/basic_response.dart';
import '../models/user.dart';
import 'api/initial_api.dart';
import 'cache/cache_manager.dart';

class UserService with CacheableMixin {
  final _api = InitialApi().dio;
  final _tokens = TokenRepository();
  static UserService? _instance;
  factory UserService() => _instance ??= UserService._();

  UserService._();

  Future<BasicResponse> register({
    required String firstName,
    required String lastName,
    required String birthDate,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final resp = await _api.post('/auth/register', data: {
        'username': email,
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate,
        'gender': gender,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      });

      return BasicResponse(resp.statusCode ?? 0, resp.data);
    } on DioException catch (e) {
      return BasicResponse(
          e.response?.statusCode ?? 0,
          e.response?.data ?? {'error': e.message}
      );
    }
  }

  Future<BasicResponse> login(String username, String password) async {
    try {
      final resp = await _api.post('/auth/login', data: {
        'loginIdentifier': username,
        'password': password,
      });
      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        final data = resp.data as Map<String, dynamic>;
        final jwt = data['jwt'] as String;
        await _tokens.saveToken(jwt);
      }
      return BasicResponse(resp.statusCode ?? 0, resp.data);
    } on DioException catch (e) {
      return BasicResponse(e.response?.statusCode ?? 0, e.response?.data ?? {'error': e.message});
    }
  }

  Future<void> logout() async {
    await _tokens.removeToken();
    // Wyczyść cache po wylogowaniu
    CacheManager.clear();
    dev.log('Cache cleared after logout');
  }

  Future<BasicResponse> deactivateAccount({String? reason}) async {
    try {
      final resp = await _api.post('/user/deactivate', queryParameters: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      if (resp.statusCode == 200) {
        await _tokens.removeToken();
      }
      return BasicResponse(resp.statusCode ?? 0, resp.data);
    } on DioException catch (e) {
      return BasicResponse(
          e.response?.statusCode ?? 0, e.response?.data ?? {'error': e.message});
    }
  }

  Future<User> getCurrentUser() async {
    const cacheKey = 'current_user';

    return cachedFetch(cacheKey, () async {
      try {
        final resp = await _api.get('/user');
        if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
          return User.fromJson(resp.data as Map<String, dynamic>);
        }
        throw Exception('Nieoczekiwana odpowiedź serwera: ${resp.statusCode}');
      } on DioException catch (e) {
        throw Exception('Błąd podczas pobierania profilu: ${e.message}');
      }
    }, ttl: Duration(minutes: 10));
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final resp = await _api.put('/user', data: userData);

      if (resp.statusCode == 200) {
        // Invaliduj cache użytkownika po aktualizacji
        CacheManager.invalidate('current_user');
        CacheManager.invalidatePattern('user_');
        dev.log('User cache invalidated after profile update');

        return {
          'success': true,
          'user': resp.data,
        };
      } else {
        return {
          'success': false,
          'error': 'Nieoczekiwana odpowiedź serwera: ${resp.statusCode}',
        };
      }
    } on DioException catch (e) {
      dev.log('Błąd podczas aktualizacji profilu: ${e.message}');

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> && errorData['error'] != null) {
          return {
            'success': false,
            'error': errorData['error'],
          };
        }
      }

      return {
        'success': false,
        'error': e.message ?? 'Nieznany błąd podczas aktualizacji profilu',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Wystąpił nieoczekiwany błąd: $e',
      };
    }
  }

  Future<String?> getProfileImage() async {
    try {
      final resp = await _api.get('/user/profile-image');
      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        return resp.data['image'] as String?;
      }
      return null;
    } on DioException catch (e) {
      dev.log('Błąd podczas pobierania zdjęcia profilu: ${e.message}');
      return null;
    }
  }

  Future<bool> uploadProfileImage(String path) async {
    try {
      String? mimeType = lookupMimeType(path);
      if (mimeType == null || !mimeType.startsWith('image/')) {
        dev.log('Nieprawidłowy format pliku: $mimeType');
        return false;
      }

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          path,
          contentType: MediaType.parse(mimeType),
        ),
      });

      final resp = await _api.post('/user/profile-image', data: formData);
      return resp.statusCode == 200;
    } on DioException catch (e) {
      dev.log('Błąd podczas wysyłania zdjęcia profilu: ${e.message}');
      if (e.response != null) {
        dev.log('Response data: ${e.response?.data}');
        dev.log('Response status: ${e.response?.statusCode}');
      }
      return false;
    }
  }
}