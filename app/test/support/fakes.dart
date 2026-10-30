import 'package:brackety/features/session/data/session_api.dart';
import 'package:dio/dio.dart';

/// Server sessions without a server: signed in from the start, or only after [login].
class FakeSessionApi implements SessionApi {
  FakeSessionApi({required this.signedIn});

  bool signedIn;
  final logins = <String>[];

  static const _tokens = SessionTokens(accessToken: 'token');

  @override
  Future<SessionTokens> login(String username, String password) async {
    if (username != password) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
      );
    }
    logins.add(username);
    signedIn = true;
    return _tokens;
  }

  @override
  Future<SessionTokens> refresh(String? refreshToken) async {
    if (!signedIn) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
      );
    }
    return _tokens;
  }

  @override
  Future<void> logout(String? refreshToken) async => signedIn = false;
}
