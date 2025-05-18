import 'package:dio/dio.dart';
import 'package:mobile/services/token_repository.dart';

class AuthInterceptor extends Interceptor {
  final _tokenRepo = TokenRepository();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenRepo.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // nieważny token → usuń i ewentualnie przekieruj do ekranu logowania
      await _tokenRepo.removeToken();
    }
    handler.next(err);
  }
}