import 'package:flutter/foundation.dart';
import 'package:mvvm/core/logging/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_reporter.g.dart';

/// App-wide crash/error sink. The global handlers (`FlutterError.onError`,
/// `PlatformDispatcher.onError`) and any `catch` site report through this
/// contract, so wiring a vendor (Sentry / Crashlytics) is a one-file swap.
abstract interface class ErrorReporter {
  /// Reports an uncaught/handled error with its stack and optional [context]
  /// (where it was caught).
  void report(Object error, StackTrace stackTrace, {String? context});

  /// Reports a Flutter framework error (from `FlutterError.onError`).
  void reportFlutterError(FlutterErrorDetails details);
}

/// Default [ErrorReporter] — forwards everything to the [AppLogger].
///
/// TEMPLATE: to ship crashes to a service, implement [ErrorReporter] against
/// its SDK (e.g. `Sentry.captureException(error, stackTrace: stackTrace)`) and
/// bind that impl in `app/run_app.dart` instead.
class LoggingErrorReporter implements ErrorReporter {
  LoggingErrorReporter(this._logger);

  final AppLogger _logger;

  @override
  void report(Object error, StackTrace stackTrace, {String? context}) {
    _logger.error(
      context == null ? 'Uncaught error' : 'Uncaught error [$context]',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void reportFlutterError(FlutterErrorDetails details) {
    _logger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  }
}

/// Bound to a [LoggingErrorReporter] in `core/bootstrap` (instance created in
/// `app/run_app.dart` so the global handlers share it).
@riverpod
ErrorReporter errorReporter(Ref ref) => throw UnimplementedError(
  'errorReporterProvider must be overridden in ProviderScope — see core/bootstrap.',
);
