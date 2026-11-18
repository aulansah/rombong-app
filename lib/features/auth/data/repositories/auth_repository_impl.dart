import '../../../../core/error/failure.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/result.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remote, required TokenStorage storage})
      : _remote = remote,
        _storage = storage;

  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  @override
  Future<Result<User>> login({required String email, required String password}) {
    return guard(() async {
      final (user, tokens) = await _remote.login(email, password);
      await _storage.save(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      return user;
    });
  }

  @override
  Future<Result<User>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return guard(() => _remote.register(name, email, password));
  }

  @override
  Future<Result<User?>> currentUser() async {
    if (await _storage.readRefreshToken() == null) return const Ok(null);

    // The interceptor refreshes an expired access token transparently, so
    // reaching 401 here means the whole session is gone.
    final result = await guard(_remote.me);
    if (result case Err(failure: UnauthorizedFailure())) {
      await _storage.clear();
      return const Ok(null);
    }
    return result;
  }

  @override
  Future<Result<void>> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken != null) {
      // Best effort: even if the server cannot be reached, the local session
      // is cleared so the user is logged out on this device.
      await guard(() => _remote.logout(refreshToken));
    }
    await _storage.clear();
    return const Ok(null);
  }
}
