import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/error_reporter.dart';
import 'package:mvvm/core/error/error_reporting_observer.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/state/mutation_state_mixin.dart';
import 'package:mvvm/core/state/remote_state_mixin.dart';
import 'package:mvvm/core/state/submission_state.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_reporting_observer_test.g.dart';

// Probe ViewModels exercising both spines, driven by an injected Either.
@riverpod
class ReadProbe extends _$ReadProbe with RemoteStateMixin<int> {
  @override
  ViewState<int> build() => const ViewState.idle();
  Future<void> run(Either<Failure, int> r) => runRequest(() async => r);
}

@riverpod
class WriteProbe extends _$WriteProbe with MutationStateMixin<int> {
  @override
  SubmissionState<int> build() => const SubmissionState.idle();
  Future<void> run(Either<Failure, int> r) => runMutation(() async => r);
}

class _FakeReporter implements ErrorReporter {
  final List<Failure> reported = <Failure>[];

  @override
  void report(Object error, StackTrace stackTrace, {String? context}) {
    if (error is Failure) reported.add(error);
  }

  @override
  void reportFlutterError(FlutterErrorDetails details) {}
}

void main() {
  late _FakeReporter reporter;
  late ProviderContainer container;

  setUp(() {
    reporter = _FakeReporter();
    container = ProviderContainer(
      observers: [ErrorReportingObserver(reporter)],
    );
  });
  tearDown(() => container.dispose());

  group('reads (ViewState.error)', () {
    test('a server failure is reported', () async {
      await container
          .read(readProbeProvider.notifier)
          .run(
            left<Failure, int>(
              const Failure.server(statusCode: 500, message: 'x'),
            ),
          );
      expect(reporter.reported, [
        const Failure.server(statusCode: 500, message: 'x'),
      ]);
    });

    test('no-connection maps to noInternet and is NOT reported', () async {
      await container
          .read(readProbeProvider.notifier)
          .run(left<Failure, int>(const Failure.noConnection()));
      expect(reporter.reported, isEmpty);
    });

    test('a validation failure is NOT reported', () async {
      await container
          .read(readProbeProvider.notifier)
          .run(left<Failure, int>(const Failure.validation(message: 'bad')));
      expect(reporter.reported, isEmpty);
    });

    test('success is NOT reported', () async {
      await container
          .read(readProbeProvider.notifier)
          .run(right<Failure, int>(1));
      expect(reporter.reported, isEmpty);
    });
  });

  group('writes (SubmissionState.failure)', () {
    test('a server failure is reported', () async {
      await container
          .read(writeProbeProvider.notifier)
          .run(left<Failure, int>(const Failure.unexpected()));
      expect(reporter.reported, [const Failure.unexpected()]);
    });

    test('an offline submit failure is NOT reported', () async {
      await container
          .read(writeProbeProvider.notifier)
          .run(left<Failure, int>(const Failure.noConnection()));
      expect(reporter.reported, isEmpty);
    });
  });
}
