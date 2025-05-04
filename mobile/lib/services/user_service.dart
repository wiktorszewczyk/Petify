import 'dart:developer' as dev;
import 'dart:math';
import 'package:dio/dio.dart';

import '../models/basic_response.dart';
import '../models/user.dart';
import 'api/initial_api.dart';

class UserService {
  static UserService? _instance;
  factory UserService() => _instance ??= UserService._();

  UserService._();

  Future<BasicResponse> register(String username, String password) async {
    dev.log('UserService.register($username)');
    try {
      final response = await InitialApi().dio.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
        },
      );
      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        return BasicResponse(e.response!.statusCode ?? 0, e.response!.data);
      } else {
        return BasicResponse(0, {'error': e.message});
      }
    }
  }

  Future<BasicResponse> login(String username, String password) async {
    dev.log('UserService.login($username)');
    try {
      final response = await InitialApi().dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      return BasicResponse(response.statusCode ?? 0, response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        return BasicResponse(e.response!.statusCode ?? 0, e.response!.data);
      } else {
        return BasicResponse(0, {'error': e.message});
      }
    }
  }

  Future<User> getCurrentUser() async {
    // TODO: podmienić na realne API.
    await Future.delayed(const Duration(milliseconds: 400));
    final rnd = Random();
    return User(
      id: 'u1',
      username: 'john_doe',
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