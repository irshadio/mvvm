import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/presentation/extensions/ref_extensions.dart';
import 'package:mvvm/core/state/view_state.dart';

// Drives `WidgetRefX.listenRefreshFailures`: a failed *refresh* (a failure that
// still carries data) must toast, while a *first-load* failure (no data) must
// not — that one is rendered by the switcher itself.
class _Probe extends Notifier<ViewState<int>> {
  @override
  ViewState<int> build() => const ViewState<int>.idle();

  // ignore: use_setters_to_change_properties test-only state driver
  void emit(ViewState<int> next) => state = next;
}

final _probeProvider = NotifierProvider<_Probe, ViewState<int>>(_Probe.new);

class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listenRefreshFailures(_probeProvider, context);
    return const SizedBox.shrink();
  }
}

void main() {
  Future<ProviderContainer> pumpHost(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: _Host())),
      ),
    );
    return container;
  }

  testWidgets('a failed refresh (data retained) surfaces a snackbar', (
    tester,
  ) async {
    final container = await pumpHost(tester);
    expect(find.byType(SnackBar), findsNothing);

    container.read(_probeProvider.notifier).emit(
      const ViewState<int>.error(
        Failure.unexpected(message: 'refresh boom'),
        previous: 7,
      ),
    );
    await tester.pump(); // run the listener
    await tester.pump(); // animate the snackbar in

    expect(find.text('refresh boom'), findsOneWidget);
  });

  testWidgets('a first-load failure (no data) does not snackbar', (
    tester,
  ) async {
    final container = await pumpHost(tester);

    container.read(_probeProvider.notifier).emit(
      const ViewState<int>.error(Failure.unexpected(message: 'first boom')),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('first boom'), findsNothing);
  });
}
