import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/state/mutation_state_mixin.dart';
import 'package:mvvm/core/state/submission_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mutation_state_mixin_test.g.dart';

// GUARD TEST. A test-only mutating ViewModel that exercises the quarantined
// `MutationStateMixin on $Notifier<SubmissionState<T>>`. If a Riverpod /
// riverpod_generator upgrade breaks that `on` clause, THIS FILE STOPS COMPILING
// — the canary for core/state/mutation_state_mixin.dart. It also verifies
// runMutation's inProgress -> success | failure mapping.
@riverpod
class ProbeMutation extends _$ProbeMutation with MutationStateMixin<int> {
  @override
  SubmissionState<int> build() => const SubmissionState.idle();

  Future<void> run(Either<Failure, int> result) =>
      runMutation(() async => result);

  Future<void> runThrowing() =>
      runMutation(() async => throw StateError('boom'));
}

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('build() starts idle', () {
    expect(
      container.read(probeMutationProvider),
      const SubmissionState<int>.idle(),
    );
  });

  test('success maps to SubmissionState.success', () async {
    await container
        .read(probeMutationProvider.notifier)
        .run(right<Failure, int>(101));
    expect(
      container.read(probeMutationProvider),
      const SubmissionState<int>.success(101),
    );
  });

  test('failure maps to SubmissionState.failure', () async {
    const failure = Failure.validation(message: 'Title is required');
    await container
        .read(probeMutationProvider.notifier)
        .run(left<Failure, int>(failure));
    expect(
      container.read(probeMutationProvider),
      const SubmissionState<int>.failure(failure),
    );
  });

  test('a THROWN error maps to SubmissionState.failure (no hang)', () async {
    await container.read(probeMutationProvider.notifier).runThrowing();
    final state = container.read(probeMutationProvider);
    // It resolves to a failure — NOT stuck on inProgress — carrying the generic
    // UnexpectedFailure (reported via ErrorReportingObserver).
    expect(state, isA<SubmissionFailure<int>>());
    expect((state as SubmissionFailure<int>).failure, isA<UnexpectedFailure>());
  });
}
