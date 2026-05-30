import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/app/app.dart';
import 'package:mvvm/core/bootstrap/bootstrap.dart';
import 'package:mvvm/core/config/app_environment.dart';
import 'package:mvvm/core/error/error_reporter.dart';
import 'package:mvvm/core/logging/app_logger.dart';
import 'package:mvvm/features/posts/posts_overrides.dart';

/// Shared composition root for every flavour entrypoint (`main.dart`,
/// `main_dev.dart`, …).
///
/// Installs the global error handlers, builds the core + feature overrides for
/// [env], and runs the app inside one [ProviderScope]. Lives in `app/` (not
/// `core/`) because it references [App]; `core` may never import `app`.
///
/// The [AppLogger] and [ErrorReporter] are created here — not via a provider —
/// because `FlutterError.onError` / `PlatformDispatcher.onError` fire before
/// (and outside) the widget tree and must share the same instances that
/// `buildCoreOverrides` then binds for in-app use.
Future<void> runMvvmApp(AppEnvironment env) async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppLogger logger = ConsoleLogger(minLevel: env.config.minLogLevel);
  final ErrorReporter reporter = LoggingErrorReporter(logger);

  // Framework (build/layout/paint) errors.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reporter.reportFlutterError(details);
  };
  // Uncaught async / platform errors that escape the framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.report(error, stack, context: 'PlatformDispatcher');
    return true;
  };

  logger.info('Starting MVVM — flavour=${env.config.name}');

  // Inferred as List<Override> from the two spreads (avoids importing the
  // riverpod_annotation `Override` type alongside flutter_riverpod here).
  final overrides = [
    ...await buildCoreOverrides(env: env, logger: logger, reporter: reporter),
    ...postsOverrides,
  ];

  runApp(ProviderScope(overrides: overrides, child: const App()));
}
