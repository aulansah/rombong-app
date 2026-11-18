import 'package:dio/dio.dart';

import '../models/auth_models.dart';

/// Talks HTTP to the Go backend. Throws DioException on failure; the
/// repository turns those into Failures.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);
  final Dio _dio;

  /// POST /auth/login → { data: { user, tokens } }
  Future<(UserModel, TokenPair)> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = res.data!['data'] as Map<String, dynamic>;
    return (
      UserModel.fromJson(data['user'] as Map<String, dynamic>),
      TokenPair.fromJson(data['tokens'] as Map<String, dynamic>),
    );
  }

  /// POST /auth/register → { data: user }
  Future<UserModel> register(String name, String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    return UserModel.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  /// GET /users/me → { data: user }
  Future<UserModel> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/me');
    return UserModel.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  /// POST /auth/logout revokes the refresh token on the server.
  Future<void> logout(String refreshToken) async {
    await _dio.post<void>('/auth/logout', data: {'refresh_token': refreshToken});
  }
}
