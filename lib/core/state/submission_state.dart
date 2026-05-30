import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:mvvm/core/error/failure.dart';

part 'submission_state.freezed.dart';

/// The UI-state union every *mutating* ViewModel (create / update / delete)
/// exposes — the write-side counterpart to `ViewState`.
///
/// Where `ViewState<T>` models a *display* lifecycle (idle / loading / data /
/// error / noInternet, carrying `previous` so a refresh is non-destructive),
/// `SubmissionState<T>` models a *submission* lifecycle. The form fields
/// themselves live in the View (text controllers + a `Form` for validation);
/// this union only tracks whether a submit is in flight and its outcome, so the
/// View can disable the action while submitting and react exactly once to
/// success / failure (see `WidgetRefX.listenSubmission`).
///
/// Consume it with Dart 3 `switch` (Freezed 3 made `.when`/`.map` legacy):
/// ```dart
/// switch (state) {
///   SubmissionIdle()                  => ...,
///   SubmissionInProgress()            => ...,
///   SubmissionSuccess(:final value)   => ...,
///   SubmissionFailure(:final failure) => ...,
/// }
/// ```
@freezed
sealed class SubmissionState<T> with _$SubmissionState<T> {
  /// Pristine — nothing has been submitted yet.
  const factory SubmissionState.idle() = SubmissionIdle<T>;

  /// A submit is in flight; the View disables the action and shows a spinner.
  const factory SubmissionState.inProgress() = SubmissionInProgress<T>;

  /// Success — carries the created / updated value.
  const factory SubmissionState.success(T value) = SubmissionSuccess<T>;

  /// Failure — carries the typed [Failure] (its `message` is always readable).
  const factory SubmissionState.failure(Failure failure) = SubmissionFailure<T>;
}

/// Switch-free accessors on [SubmissionState].
extension SubmissionStateX<T> on SubmissionState<T> {
  /// Whether a submit is currently in flight — use it to disable the action.
  bool get isInProgress => this is SubmissionInProgress<T>;
}
