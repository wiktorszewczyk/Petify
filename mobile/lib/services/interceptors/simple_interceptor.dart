import 'dart:developer';
import 'package:dio/dio.dart';

class SimpleInterceptor extends Interceptor {

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('SimpleInterceptor Request: ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('SimpleInterceptor Response: ${response.statusCode} ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('SimpleInterceptor Error: ${err.message}');
    super.onError(err, handler);
  }
}