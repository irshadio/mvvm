import 'package:mvvm/core/storage/secure_store.dart';
import 'package:remote_client/remote_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unauthorized_handler.g.dart';

/// Invoked by `remote_client`'s `AuthInterceptor` when a request is rejected as
/// unauthorized and token refresh fails. Clears stale credentials.
///
/// TEMPLATE: when an auth feature exists, also navigate to login via
/// `rootNavigatorKey` (see `core/routing`).
class AppUnauthorizedHandler implements UnauthorizedHandler {
  AppUnauthorizedHandler(this._secureStore);

  final SecureStore _secureStore;

  @override
  Future<void> handleUnauthorized() => _secureStore.clear();
}

/// Bound to [AppUnauthorizedHandler] in `core/bootstrap`.
@riverpod
UnauthorizedHandler unauthorizedHandler(Ref ref) => throw UnimplementedError(
  'unauthorizedHandlerProvider must be overridden in ProviderScope — see core/bootstrap.',
);
