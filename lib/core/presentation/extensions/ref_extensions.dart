import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/presentation/extensions/context_extensions.dart';
import 'package:mvvm/core/state/submission_state.dart';
import 'package:mvvm/core/state/view_state.dart';
// ProviderListenable is exported by riverpod_annotation, not flutter_riverpod.
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// View-side helpers on [WidgetRef].
extension WidgetRefX on WidgetRef {
  /// Surfaces *refresh* failures as a snackbar without disturbing the data
  /// already on screen.
  ///
  /// When a reload fails but previous data is still shown (the
  /// `ViewStateSwitcher` keeps it visible), the error would otherwise be
  /// invisible. Call this once in `build` for every `ViewStateSwitcher`-backed
  /// screen — it is a required part of the View pattern (see `posts_view.dart`,
  /// enforced by `mvvm-verifier`). First-load failures are rendered by the
  /// switcher itself and are intentionally not re-surfaced here.
  void listenRefreshFailures<T>(
    ProviderListenable<ViewState<T>> provider,
    BuildContext context,
  ) {
    listen<ViewState<T>>(provider, (previous, next) {
      // Only a failure that still has data behind it is a silent refresh error.
      if (next.dataOrNull == null) return;
      final message = switch (next) {
        ViewError<T>(:final failure) => failure.message,
        ViewNoInternet<T>() => 'No internet connection',
        _ => null,
      };
      if (message != null && context.mounted) {
        context.showSnackBar(message, isError: true);
      }
    });
  }

  /// Reacts ONCE to a mutation's terminal transition — the write-side
  /// counterpart to [listenRefreshFailures].
  ///
  /// A mutating View calls this in `build`: on [SubmissionSuccess] it runs
  /// [onSuccess] (e.g. pop the form + toast); on [SubmissionFailure] it runs
  /// [onFailure], defaulting to an error snackbar with the failure message.
  /// `idle` / `inProgress` transitions are handled by the View watching the
  /// state (to disable the action), not here.
  void listenSubmission<T>(
    ProviderListenable<SubmissionState<T>> provider,
    BuildContext context, {
    required void Function(T value) onSuccess,
    void Function(Failure failure)? onFailure,
  }) {
    listen<SubmissionState<T>>(provider, (previous, next) {
      if (!context.mounted) return;
      switch (next) {
        case SubmissionSuccess<T>(:final value):
          onSuccess(value);
        case SubmissionFailure<T>(:final failure):
          if (onFailure != null) {
            onFailure(failure);
          } else {
            context.showSnackBar(failure.message, isError: true);
          }
        case SubmissionIdle<T>() || SubmissionInProgress<T>():
          break;
      }
    });
  }
}
