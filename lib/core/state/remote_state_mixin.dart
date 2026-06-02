import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// The reusable `api -> data -> state` spine shared by every ViewModel.
///
/// Mix it into a code-generated Notifier whose state is `ViewState<T>`; it
/// drives the state machine `loading -> (data | error | noInternet)` from an
/// `Either` returned by a repository, so ViewModels never repeat that
/// boilerplate:
///
/// ```dart
/// @riverpod
/// class PostsVm extends _$PostsVm with RemoteStateMixin<List<Post>> {
///   @override
///   ViewState<List<Post>> build() => const ViewState.idle();
///
///   Future<void> load() =>
///       runRequest(() => ref.read(postRepositoryProvider).getPosts());
/// }
/// ```
///
/// ⚠️ QUARANTINE — the `on` clause targets `$Notifier`, the base that
/// `riverpod_generator` emits for `@riverpod` classes. `$Notifier` is marked
/// "implementation detail of riverpod_generator. Do not use." It is the ONLY
/// sanctioned-API exception in this codebase and is confined to THIS file: no
/// feature code ever names `$Notifier`. The empirically-verified reason is that
/// the generated `_$Xxx` extends `$Notifier<State>` (NOT the public
/// `Notifier<State>`), so a public `on Notifier<...>` clause will not attach.
/// After ANY Riverpod / riverpod_generator bump, re-run the guard test in
/// `test/core/remote_state_mixin_test.dart`; if it fails, re-read the generated
/// base class and update the `on` clause here only.
mixin RemoteStateMixin<T> on $Notifier<ViewState<T>> {
  /// Monotonic token identifying the most recently started request. Only that
  /// request may commit `state`, so overlapping requests (a refresh racing an
  /// in-flight load-more, a double-tapped retry) cannot clobber a newer result
  /// — `runRequest` is sequenced, not last-writer-wins.
  int _activeRequestId = 0;

  /// Snapshots the current data, sets `loading(previous:)`, awaits [request],
  /// then — if still mounted AND not superseded by a newer request — maps the
  /// result: `NoConnectionFailure -> noInternet`, any other `Failure -> error`,
  /// success `-> data`. The carried `previous` keeps the last data visible
  /// across a refresh and a failed refresh (see `ViewState`).
  Future<void> runRequest(
    Future<Either<Failure, T>> Function() request,
  ) async {
    final previous = state.dataOrNull;
    final requestId = ++_activeRequestId;
    state = ViewState<T>.loading(previous: previous);
    final Either<Failure, T> result;
    try {
      result = await request();
    } on Object {
      // A repository/mapping that THROWS (rather than returning a `Left`) must
      // not strand the View on a permanent spinner. Map any unexpected throw to
      // an error state, carrying `previous`; the `ErrorReportingObserver`
      // forwards the resulting `UnexpectedFailure` to telemetry, so the throw
      // is neither silent nor invisible.
      if (!_isCurrent(requestId)) return;
      state = ViewState<T>.error(
        const Failure.unexpected(),
        previous: previous,
      );
      return;
    }
    // Drop the result if the provider was disposed (e.g. the View was popped),
    // or a newer request superseded this one while it was in flight.
    if (!_isCurrent(requestId)) return;
    state = result.fold(
      (failure) => switch (failure) {
        NoConnectionFailure() => ViewState<T>.noInternet(previous: previous),
        _ => ViewState<T>.error(failure, previous: previous),
      },
      ViewState<T>.data,
    );
  }

  /// Still mounted and still the latest request — safe to commit `state`.
  bool _isCurrent(int requestId) =>
      ref.mounted && requestId == _activeRequestId;
}
