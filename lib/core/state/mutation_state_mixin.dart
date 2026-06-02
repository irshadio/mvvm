import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/state/submission_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// The reusable `api -> submission -> state` spine shared by every *mutating*
/// ViewModel — the write-side counterpart to `RemoteStateMixin`.
///
/// Mix it into a code-generated Notifier whose state is `SubmissionState<T>`;
/// it drives the machine `inProgress -> (success | failure)` from an `Either`
/// returned by a repository, so create / update / delete ViewModels never
/// repeat that boilerplate:
///
/// ```dart
/// @riverpod
/// class CreateFooVm extends _$CreateFooVm with MutationStateMixin<Foo> {
///   @override
///   SubmissionState<Foo> build() => const SubmissionState.idle();
///
///   Future<void> submit(FooInput input) =>
///       runMutation(() => ref.read(fooRepositoryProvider).create(input));
/// }
/// ```
///
/// ⚠️ QUARANTINE — like `RemoteStateMixin`, the `on` clause targets
/// `$Notifier`, the base `riverpod_generator` emits for `@riverpod` classes,
/// marked "implementation detail … Do not use." `$Notifier` is confined to
/// `core/state/` — THIS file and `remote_state_mixin.dart`; no feature code
/// ever names it. The empirically-verified reason is that the generated `_$Xxx`
/// extends `$Notifier<State>` (NOT the public `Notifier<State>`), so a public
/// `on Notifier<...>` clause will not attach. After ANY Riverpod /
/// riverpod_generator bump, re-run the guard test in
/// `test/core/mutation_state_mixin_test.dart`.
mixin MutationStateMixin<T> on $Notifier<SubmissionState<T>> {
  /// Sets `inProgress`, awaits [request], then — if the notifier is still
  /// mounted — maps the result: success `-> success(value)`, any
  /// `Failure -> failure(failure)`. Unlike a refresh there is no `previous` to
  /// preserve: a form submit either succeeds or surfaces its error.
  Future<void> runMutation(
    Future<Either<Failure, T>> Function() request,
  ) async {
    state = SubmissionState<T>.inProgress();
    final Either<Failure, T> result;
    try {
      result = await request();
    } on Object {
      // A repository/mapping that THROWS (rather than returning a `Left`) must
      // not strand the form in a permanent `inProgress`. Map any unexpected
      // throw to a failure; the `ErrorReportingObserver` forwards the resulting
      // `UnexpectedFailure` to telemetry, so the throw is neither silent nor
      // invisible.
      if (!ref.mounted) return;
      state = SubmissionState<T>.failure(const Failure.unexpected());
      return;
    }
    // The provider may have been disposed (e.g. the form was popped) while the
    // request was in flight; assigning `state` after that would throw.
    if (!ref.mounted) return;
    state = result.fold(
      SubmissionState<T>.failure,
      SubmissionState<T>.success,
    );
  }
}
