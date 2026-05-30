import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:mvvm/core/error/failure.dart';

part 'view_state.freezed.dart';

/// The single UI-state union every ViewModel exposes and every View renders
/// through `ViewStateSwitcher`.
///
/// We use a Freezed sealed union rather than Riverpod's `AsyncValue` because
/// `AsyncValue` models only data / loading / error. This app needs `idle`
/// (nothing requested yet) and `noInternet` as first-class, explicit states.
///
/// `loading`, `error` and `noInternet` each carry an optional `previous` value
/// — the last successfully-loaded data. This is what makes a *refresh*
/// non-destructive: the View keeps showing the current data while a reload is
/// in flight (or after it fails) instead of blanking to a spinner. The
/// `RemoteStateMixin` populates `previous` automatically; read it anywhere via
/// [ViewStateX.dataOrNull].
///
/// Consume it with Dart 3 `switch` (Freezed 3 made `.when`/`.map` legacy):
/// ```dart
/// switch (state) {
///   ViewIdle()                  => ...,
///   ViewLoading(:final previous) => ...,
///   ViewData(:final value)      => ...,
///   ViewError(:final failure)   => ...,
///   ViewNoInternet()            => ...,
/// }
/// ```
@freezed
sealed class ViewState<T> with _$ViewState<T> {
  /// Initial state — no request has been made yet.
  const factory ViewState.idle() = ViewIdle<T>;

  /// A request is in flight. [previous] is the last loaded data, if any, so the
  /// UI can keep rendering it during a refresh instead of blanking.
  const factory ViewState.loading({T? previous}) = ViewLoading<T>;

  /// Success — carries the loaded data.
  const factory ViewState.data(T value) = ViewData<T>;

  /// Failure — carries the typed [Failure]. [previous] is the last loaded data,
  /// if any (a failed *refresh*), so the UI can keep showing it.
  const factory ViewState.error(Failure failure, {T? previous}) = ViewError<T>;

  /// No real internet reachability. [previous] is the last loaded data, if any.
  const factory ViewState.noInternet({T? previous}) = ViewNoInternet<T>;
}

/// Shared, switch-free accessors on [ViewState].
extension ViewStateX<T> on ViewState<T> {
  /// The most recent successful value, or `null` if none has loaded yet.
  ///
  /// Returns the value of [ViewData], or the `previous` carried by a refreshing
  /// [ViewLoading] / failed [ViewError] / [ViewNoInternet]. Lets a View keep
  /// rendering data during a refresh, and lets a ViewModel snapshot the current
  /// data before reloading.
  T? get dataOrNull => switch (this) {
    ViewData<T>(:final value) => value,
    ViewLoading<T>(:final previous) => previous,
    ViewError<T>(:final previous) => previous,
    ViewNoInternet<T>(:final previous) => previous,
    ViewIdle<T>() => null,
  };

  /// Whether a request is currently in flight (initial load or refresh).
  bool get isLoading => this is ViewLoading<T>;
}
