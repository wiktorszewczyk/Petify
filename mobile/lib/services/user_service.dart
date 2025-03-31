import 'dart:developer';
import 'package:dio/dio.dart';

import '../model/basic_response.dart';
import 'api/initial_api.dart';

class UserService {
  static UserService? _instance;
  factory UserService() => _instance ??= UserService._();

  UserService._();

  Future<BasicResponse> register(String username, String password) async {
    log('UserService.register($username)');
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
    log('UserService.login($username)');
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
}