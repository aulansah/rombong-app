import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the access and refresh tokens live.
abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> save({required String accessToken, required String refreshToken});
  Future<void> clear();
}

/// Stores tokens in the platform keystore (Android Keystore, iOS Keychain).
/// SharedPreferences would keep them in plain text.
///
/// The access token is also cached in memory because it is read on every
/// request and keystore reads are comparatively slow.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  String? _accessToken;
  bool _loaded = false;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  @override
  Future<String?> readAccessToken() async {
    if (!_loaded) {
      _accessToken = await _storage.read(key: _accessKey);
      _loaded = true;
    }
    return _accessToken;
  }

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> save({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _loaded = true;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _loaded = true;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
