import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/core/presentation/extensions/context_extensions.dart';
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
}
