import 'dart:developer' as dev;
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:mobile/services/token_repository.dart';

import '../models/basic_response.dart';
import '../models/user.dart';
import 'api/initial_api.dart';

class UserService {
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
    String? email,
    String? phoneNumber,
    required String password,
    int? shelterId,
    required bool applyAsVolunteer,
  }) async {
    try {
      String username;
      if (email != null && email.isNotEmpty) {
        username = email;
      } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
        username = phoneNumber;
      } else {
        throw Exception('Either email or phone number must be provided');
      }

      final resp = await _api.post('/auth/register', data: {
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate,
        'gender': gender,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      });

      if (resp.statusCode == 200) {
        await login(username, password);
      }

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
  }

  Future<User> getCurrentUser() async {
    try {
      final resp = await _api.get('/user');
      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        return User.fromJson(resp.data as Map<String, dynamic>);
      }
      throw Exception('Nieoczekiwana odpowiedź serwera: ${resp.statusCode}');
    } on DioException catch (e) {
      throw Exception('Błąd podczas pobierania profilu: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final resp = await _api.put('/user', data: userData);

      if (resp.statusCode == 200) {
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
}