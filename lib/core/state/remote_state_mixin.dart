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
  /// Snapshots the current data, sets `loading(previous:)`, awaits [request],
  /// then — if still mounted — maps the result: `NoConnectionFailure ->
  /// noInternet`, any other `Failure -> error`, success `-> data`. The carried
  /// `previous` keeps the last data visible across a refresh and a failed
  /// refresh (see `ViewState`).
  Future<void> runRequest(
    Future<Either<Failure, T>> Function() request,
  ) async {
    final previous = state.dataOrNull;
    state = ViewState<T>.loading(previous: previous);
    final result = await request();
    // The provider may have been disposed (e.g. the View was popped) while the
    // request was in flight; assigning `state` after that would throw.
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => switch (failure) {
        NoConnectionFailure() => ViewState<T>.noInternet(previous: previous),
        _ => ViewState<T>.error(failure, previous: previous),
      },
      ViewState<T>.data,
    );
  }
}
