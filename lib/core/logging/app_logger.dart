import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_logger.g.dart';

/// Severity for [AppLogger]. Ordered: `debug < info < warning < error`.
enum LogLevel { debug, info, warning, error }

/// App-wide structured logging contract.
///
/// Features depend on this abstraction, never on `print` (banned) or a concrete
/// logger, so the sink is swappable (console in dev, a remote aggregator in
/// prod) and mockable in tests.
abstract interface class AppLogger {
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  void debug(String message);
  void info(String message);
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
}

/// `dart:developer`-backed [AppLogger]. Drops anything below `minLevel`
/// (set per flavour from `EnvConfig.minLogLevel`).
class ConsoleLogger implements AppLogger {
  ConsoleLogger({this.minLevel = LogLevel.debug});

  /// Lowest level this logger emits.
  final LogLevel minLevel;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index) return;
    developer.log(
      message,
      name: 'mvvm',
      level: _value(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void debug(String message) => log(LogLevel.debug, message);

  @override
  void info(String message) => log(LogLevel.info, message);

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  // Maps to dart:developer level values (≈ package:logging).
  int _value(LogLevel level) => switch (level) {
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
  };
}

/// Bound to a [ConsoleLogger] in `core/bootstrap` (the instance is created in
/// `app/run_app.dart` so the global error handlers share it).
@riverpod
AppLogger appLogger(Ref ref) => throw UnimplementedError(
  'appLoggerProvider must be overridden in ProviderScope — see core/bootstrap.',
);
