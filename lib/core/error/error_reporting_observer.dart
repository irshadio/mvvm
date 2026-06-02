import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/core/error/error_reporter.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/state/submission_state.dart';
import 'package:mvvm/core/state/view_state.dart';

/// Bridges *handled* domain failures to the [ErrorReporter].
///
/// `runRequest` / `runMutation` route failures into `ViewState.error` /
/// `SubmissionState.failure` instead of throwing, so the global
/// `FlutterError.onError` / `PlatformDispatcher.onError` handlers never see
/// them. Without this, a production build gets ZERO telemetry on
/// server/network/cache failures — they only ever reach the UI.
///
/// This observer watches every Notifier's state transitions and reports the
/// failures that indicate a real *system* problem, while ignoring the expected,
/// user-facing ones (offline, validation, session-expiry, cancellation) that
/// would only be telemetry noise.
///
/// It is wired ONCE at the composition root (`app/run_app.dart`) via
/// `ProviderScope(observers: [...])`, so ViewModels — and their tests — stay
/// untouched. (`ProviderObserver` is `abstract base`, hence `final … extends`.)
final class ErrorReportingObserver extends ProviderObserver {
  const ErrorReportingObserver(this._reporter);

  final ErrorReporter _reporter;

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      _maybeReport(context, value);

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) => _maybeReport(context, newValue);

  void _maybeReport(ProviderObserverContext context, Object? state) {
    final failure = _reportableFailure(state);
    if (failure == null) return;
    _reporter.report(
      failure,
      StackTrace.current,
      context: '${context.provider}',
    );
  }

  /// The failure worth reporting, or `null` to ignore. Pulls the failure out of
  /// an error state, then drops the expected / non-actionable cases.
  Failure? _reportableFailure(Object? state) {
    final failure = switch (state) {
      ViewError<Object?>(:final failure) => failure,
      SubmissionFailure<Object?>(:final failure) => failure,
      _ => null,
    };
    return switch (failure) {
      // Expected / user-facing — not crash-worthy telemetry.
      null ||
      NoConnectionFailure() ||
      ValidationFailure() ||
      UnauthorizedFailure() ||
      CancelledFailure() => null,
      // System problems: server, network, timeout, cache, unexpected.
      _ => failure,
    };
  }
}
