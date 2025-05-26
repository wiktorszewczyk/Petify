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

  Future<Response> fetchProfile() {
    return _api.get('/user');
  }

  Future<User> getCurrentUser() async {
    // TODO: podmienić na realne API.
    await Future.delayed(const Duration(milliseconds: 400));
    final rnd = Random();
    return User(
      id: 'u1',
      username: 'john_doe',
      role: 'user',
      firstName: 'Jan',
      lastName: 'Kowalski',
      profileImageUrl: null,
      location: 'Warszawa',
      level: 4,
      experiencePoints: 230,
      nextLevelPoints: 400,
      likedPetsCount: 17,
      supportedPetsCount: 3,
      achievementsCount: 12,
      recentActivities: List.generate(5, (i) => _fakeActivity(i, rnd)),
    );
  }

  Map<String, dynamic> _fakeActivity(int i, Random r) => {
    'type': ['like', 'donation', 'achievement', 'share', 'visit'][i % 5],
    'timestamp': '${i + 1} h temu',
    'petName': 'Burek',
    'points': i.isEven ? 20 : null,
  };
}