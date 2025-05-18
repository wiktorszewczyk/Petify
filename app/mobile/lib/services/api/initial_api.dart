import 'package:dio/dio.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/logging_interceptor.dart';
import '../../settings.dart';

class InitialApi {
  late final Dio dio;

  static final InitialApi _singleton = InitialApi._internal();
  factory InitialApi() => _singleton;

  InitialApi._internal() {
    dio = _createDio();
  }

  Dio _createDio() {
    final d = Dio(BaseOptions(
      baseUrl: Settings.getServerUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ));
    d.interceptors
      ..add(LoggingInterceptor())
      ..add(AuthInterceptor());
    return d;
  }
}