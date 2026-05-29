import 'package:mvvm/core/storage/secure_store.dart';
import 'package:remote_client/remote_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_provider.g.dart';

/// Supplies access tokens to `remote_client`'s `AuthInterceptor`, backed by
/// [SecureStore]. `remote_client.TokenProvider` is fully async, so we read
/// secure storage directly (no in-memory cache needed).
class SecureTokenProvider implements TokenProvider {
  SecureTokenProvider(this._secureStore);

  final SecureStore _secureStore;

  @override
  Future<String?> getAccessToken() => _secureStore.readAccessToken();

  @override
  Future<bool> hasValidToken() async {
    final token = await _secureStore.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> refreshToken() async {
    // TEMPLATE: call your refresh-token endpoint, persist the new token to
    // [SecureStore] and return it. Returning null tells the AuthInterceptor
    // refresh is unavailable, triggering the UnauthorizedHandler.
    return null;
  }
}

/// Bound to [SecureTokenProvider] in `core/bootstrap`.
@riverpod
TokenProvider tokenProvider(Ref ref) => throw UnimplementedError(
  'tokenProviderProvider must be overridden in ProviderScope — see core/bootstrap.',
);
