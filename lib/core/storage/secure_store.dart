import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_store.g.dart';

/// Thin, typed wrapper over `flutter_secure_storage` for sensitive values
/// (tokens, secrets). Features never touch `FlutterSecureStorage` directly —
/// they depend on this so key names and serialisation live in one place.
class SecureStore {
  SecureStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  /// Wipes all secure values (e.g. on logout / 401).
  Future<void> clear() => _storage.deleteAll();
}

@riverpod
SecureStore secureStore(Ref ref) => SecureStore(const FlutterSecureStorage());
