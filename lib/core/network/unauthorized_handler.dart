import 'package:remote_client/remote_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/secure_store.dart';

part 'unauthorized_handler.g.dart';

/// Invoked by `remote_client`'s `AuthInterceptor` when a request is rejected as
/// unauthorized and token refresh fails. Clears stale credentials.
///
/// TEMPLATE: when an auth feature exists, also navigate to the login screen via
/// a global navigator key (see `core/routing`).
class AppUnauthorizedHandler implements UnauthorizedHandler {
  AppUnauthorizedHandler(this._secureStore);

  final SecureStore _secureStore;

  @override
  Future<void> handleUnauthorized() async {
    await _secureStore.clear();
  }
}

@riverpod
UnauthorizedHandler unauthorizedHandler(Ref ref) =>
    AppUnauthorizedHandler(ref.watch(secureStoreProvider));
