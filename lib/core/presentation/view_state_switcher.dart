import 'package:flutter/material.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/presentation/widgets/state_views.dart';
import 'package:mvvm/core/state/view_state.dart';

/// Maps a [ViewState] to a widget — the single, reusable "view switcher".
///
/// Only [onData] is required; the other states fall back to the app's default
/// loading / error / no-internet views. Uses Dart 3 `switch` (Freezed 3 made
/// `.when`/`.map` legacy), so adding a `ViewState` case makes this fail to
/// compile until handled.
///
/// ```dart
/// ViewStateSwitcher<List<Post>>(
///   state: ref.watch(postsVmProvider),
///   onRetry: () => ref.read(postsVmProvider.notifier).load(),
///   onData: (posts) => PostList(posts: posts),
/// )
/// ```
class ViewStateSwitcher<T> extends StatelessWidget {
  const ViewStateSwitcher({
    required this.state,
    required this.onData,
    super.key,
    this.onIdle,
    this.onLoading,
    this.onError,
    this.onNoInternet,
    this.onRetry,
  });

  /// The state to render.
  final ViewState<T> state;

  /// Builds the success UI from the loaded data.
  final Widget Function(T data) onData;

  /// Optional override for `ViewState.idle` (default: empty).
  final WidgetBuilder? onIdle;

  /// Optional override for `ViewState.loading` (default: [AppLoadingView]).
  final WidgetBuilder? onLoading;

  /// Optional override for `ViewState.error` (default: [AppErrorView]).
  final Widget Function(BuildContext context, Failure failure)? onError;

  /// Optional override for `ViewState.noInternet`
  /// (default: [AppNoInternetView]).
  final WidgetBuilder? onNoInternet;

  /// Retry callback forwarded to the default error / no-internet views.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewIdle<T>() => onIdle?.call(context) ?? const SizedBox.shrink(),
      ViewLoading<T>() => onLoading?.call(context) ?? const AppLoadingView(),
      ViewData<T>(:final value) => onData(value),
      ViewError<T>(:final failure) =>
        onError?.call(context, failure) ??
            AppErrorView(failure: failure, onRetry: onRetry),
      ViewNoInternet<T>() =>
        onNoInternet?.call(context) ?? AppNoInternetView(onRetry: onRetry),
    };
  }
}
