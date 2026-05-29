import 'package:remote_client/remote_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity.g.dart';

/// Real internet *reachability* (not just interface state) via
/// `remote_client`'s `ConnectivityServiceImpl`, which performs parallel DNS
/// probes to highly-available hosts with a short result cache.
@riverpod
ConnectivityService connectivityService(Ref ref) => ConnectivityServiceImpl();

/// Reactive reachability for a global "no internet" indicator.
///
/// Polls the [connectivityService] on an interval; the service's own 5s result
/// cache keeps the DNS probes cheap. Widgets can `ref.watch` this to show an
/// offline banner; per-request handling still flows through
/// `Failure.noConnection -> ViewState.noInternet`.
@riverpod
Stream<bool> connectivityStatus(Ref ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.isConnected();
  yield* Stream<void>.periodic(const Duration(seconds: 10))
      .asyncMap((_) => service.isConnected());
}
