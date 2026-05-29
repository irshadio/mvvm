import 'package:remote_client/remote_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_client_provider.g.dart';

/// The single configured [RemoteClient] for the app. Every remote data source
/// depends on this provider; no feature constructs its own client.
///
/// Bound in `core/bootstrap`, where auth, retry, logging and response parsing
/// are wired once (it composes the token provider + unauthorized handler).
@riverpod
RemoteClient remoteClient(Ref ref) => throw UnimplementedError(
  'remoteClientProvider must be overridden in ProviderScope — see core/bootstrap.',
);
