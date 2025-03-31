import 'package:dio/dio.dart';
import '../interceptors/simple_interceptor.dart';
import '../../settings.dart';

class InitialApi {
  late final Dio dio;
  late final Dio tokenDio;

  static final InitialApi _singleton = InitialApi._internal();
  factory InitialApi() => _singleton;

  InitialApi._internal() {
    dio = createDio();
    tokenDio = Dio(BaseOptions(baseUrl: Settings.getServerUrl()));
  }

  Dio createDio() {
    var dio = Dio(BaseOptions(
      baseUrl: Settings.getServerUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.addAll([
      SimpleInterceptor(),
    ]);

    return dio;
  }
}
