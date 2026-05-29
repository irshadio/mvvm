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
/// Consume it with Dart 3 `switch` (Freezed 3 made `.when`/`.map` legacy):
/// ```dart
/// switch (state) {
///   ViewIdle()            => ...,
///   ViewLoading()         => ...,
///   ViewData(:final value)=> ...,
///   ViewError(:final failure) => ...,
///   ViewNoInternet()      => ...,
/// }
/// ```
@freezed
sealed class ViewState<T> with _$ViewState<T> {
  /// Initial state — no request has been made yet.
  const factory ViewState.idle() = ViewIdle<T>;

  /// A request is in flight.
  const factory ViewState.loading() = ViewLoading<T>;

  /// Success — carries the loaded data.
  const factory ViewState.data(T value) = ViewData<T>;

  /// Failure — carries the typed [Failure].
  const factory ViewState.error(Failure failure) = ViewError<T>;

  /// No real internet reachability.
  const factory ViewState.noInternet() = ViewNoInternet<T>;
}
