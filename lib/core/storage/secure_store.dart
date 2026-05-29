import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_store.g.dart';

/// Contract for sensitive key/value storage (tokens, secrets).
///
/// Features depend on this abstraction, never on `flutter_secure_storage`
/// directly — so the implementation is swappable and mockable in tests.
abstract interface class SecureStore {
  Future<String?> readAccessToken();
  Future<void> writeAccessToken(String token);
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String token);

  /// Wipes all secure values (e.g. on logout / 401).
  Future<void> clear();
}

/// `flutter_secure_storage`-backed [SecureStore].
class SecureStoreImpl implements SecureStore {
  SecureStoreImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  @override
  Future<void> clear() => _storage.deleteAll();
}

/// Bound to [SecureStoreImpl] in `core/bootstrap`. Throws if read without an
/// override, so the composition root is the single source of wiring truth.
@riverpod
SecureStore secureStore(Ref ref) => throw UnimplementedError(
  'secureStoreProvider must be overridden in ProviderScope — see core/bootstrap.',
);
