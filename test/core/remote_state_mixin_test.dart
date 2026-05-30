import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/state/remote_state_mixin.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_state_mixin_test.g.dart';

// GUARD TEST. A test-only ViewModel that exercises the quarantined
// `RemoteStateMixin on $Notifier<ViewState<T>>`. If a Riverpod /
// riverpod_generator upgrade breaks that `on` clause, THIS FILE STOPS COMPILING
// — the canary for the pattern in core/state/remote_state_mixin.dart. It also
// verifies runRequest's loading -> data | error | noInternet mapping.
@riverpod
class ProbeViewModel extends _$ProbeViewModel with RemoteStateMixin<int> {
  @override
  ViewState<int> build() => const ViewState.idle();

  Future<void> run(Either<Failure, int> result) =>
      runRequest(() async => result);
}

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('build() starts idle', () {
    expect(
      container.read(probeViewModelProvider),
      const ViewState<int>.idle(),
    );
  });

  test('success maps to ViewState.data', () async {
    await container
        .read(probeViewModelProvider.notifier)
        .run(right<Failure, int>(42));
    expect(
      container.read(probeViewModelProvider),
      const ViewState<int>.data(42),
    );
  });

  test('NoConnectionFailure maps to ViewState.noInternet', () async {
    await container
        .read(probeViewModelProvider.notifier)
        .run(left<Failure, int>(const Failure.noConnection()));
    expect(
      container.read(probeViewModelProvider),
      const ViewState<int>.noInternet(),
    );
  });

  test('other Failure maps to ViewState.error', () async {
    const failure = Failure.server(statusCode: 500, message: 'boom');
    await container
        .read(probeViewModelProvider.notifier)
        .run(left<Failure, int>(failure));
    expect(
      container.read(probeViewModelProvider),
      const ViewState<int>.error(failure),
    );
  });

  test('a failed refresh retains the previous data', () async {
    final notifier = container.read(probeViewModelProvider.notifier);
    await notifier.run(right<Failure, int>(42)); // -> data(42)
    await notifier.run(left<Failure, int>(const Failure.noConnection()));
    final state = container.read(probeViewModelProvider);
    expect(state, isA<ViewNoInternet<int>>());
    expect(state.dataOrNull, 42);
  });
}
