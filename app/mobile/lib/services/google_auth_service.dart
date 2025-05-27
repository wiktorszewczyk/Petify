import 'dart:developer' as dev;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:mobile/services/token_repository.dart';
import '../models/basic_response.dart';
import 'api/initial_api.dart';

class GoogleAuthService {
  final Dio _api = InitialApi().dio;
  final TokenRepository _tokens = TokenRepository();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Loguje przez Google, wymienia token i zapisuje JWT
  Future<BasicResponse> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return BasicResponse(0, {'error': 'Użytkownik anulował logowanie'});
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      if (accessToken == null) {
        return BasicResponse(0, {'error': 'Brak access tokenu z Google'});
      }

      print('Google user signed in: ${googleUser.email}');
      print('Google access token: $accessToken');

      final resp = await _api.post(
        '/auth/oauth2/exchange',
        data: {
          'provider': 'google',
          'access_token': accessToken,
        },
      );

      final status = resp.statusCode ?? 0;
      if (status >= 200 && status < 300 && resp.data is Map<String, dynamic>) {
        final data = resp.data as Map<String, dynamic>;
        final jwt = data['jwt'] as String?;
        if (jwt != null) {
          await _tokens.saveToken(jwt);
        } else {
          dev.log('Brak pola jwt w response', error: resp.data);
          return BasicResponse(500, {'error': 'Brak JWT w odpowiedzi serwera'});
        }
        return BasicResponse(status, data);
      }

      return BasicResponse(status, resp.data);
    } on DioException catch (e) {
      dev.log('GoogleAuthService.signInWithGoogle error', error: e);
      return BasicResponse(
        e.response?.statusCode ?? 0,
        e.response?.data ?? {'error': e.message},
      );
    } catch (e) {
      dev.log('GoogleAuthService.signInWithGoogle unexpected error', error: e);
      return BasicResponse(0, {'error': e.toString()});
    }
  }

  /// Wylogowanie (lokalnie)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _tokens.removeToken();
  }

  /// Sprawdza, czy mamy zapisany JWT
  Future<bool> isSignedIn() async {
    final token = await _tokens.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Pobiera profil użytkownika z backendu
  Future<BasicResponse> getCurrentUser() async {
    try {
      final resp = await _api.get('/auth/oauth2/user-info');
      return BasicResponse(resp.statusCode ?? 0, resp.data);
    } on DioException catch (e) {
      return BasicResponse(
        e.response?.statusCode ?? 0,
        e.response?.data ?? {'error': e.message},
      );
    }
  }
}