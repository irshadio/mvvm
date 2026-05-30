import 'package:mvvm/core/config/app_config.dart';
import 'package:mvvm/core/logging/app_logger.dart';

/// The build flavour the app is running as.
///
/// Chosen by the entrypoint (`lib/main_dev.dart` / `main_staging.dart` /
/// `main_prod.dart`) — never inferred at runtime — and carries the
/// environment-specific [config]. See `docs/FLAVORS.md`.
enum AppEnvironment {
  dev,
  staging,
  prod;

  /// Resolves the flavour from the `APP_ENV` dart-define (default: [dev]).
  /// Used by the flavour-less default `lib/main.dart`; the per-flavour
  /// entrypoints pass the value explicitly.
  static AppEnvironment fromEnv() =>
      switch (const String.fromEnvironment('APP_ENV', defaultValue: 'dev')) {
        'prod' => AppEnvironment.prod,
        'staging' => AppEnvironment.staging,
        _ => AppEnvironment.dev,
      };

  /// The configuration for this flavour.
  EnvConfig get config => switch (this) {
    // NOTE: all three point at the same demo API. Give each flavour its own
    // base URL here (and per-flavour secrets via separate `.env.<flavour>`
    // files + `@Envied` classes) for a real backend.
    AppEnvironment.dev => const EnvConfig(
      name: 'dev',
      apiBaseUrl: AppConfig.apiBaseUrl,
      minLogLevel: LogLevel.debug,
    ),
    AppEnvironment.staging => const EnvConfig(
      name: 'staging',
      apiBaseUrl: AppConfig.apiBaseUrl,
      minLogLevel: LogLevel.info,
    ),
    AppEnvironment.prod => const EnvConfig(
      name: 'prod',
      apiBaseUrl: AppConfig.apiBaseUrl,
      minLogLevel: LogLevel.warning,
    ),
  };
}

/// Per-flavour configuration. Extend with feature flags, a Sentry DSN, etc.
class EnvConfig {
  const EnvConfig({
    required this.name,
    required this.apiBaseUrl,
    required this.minLogLevel,
  });

  /// Short flavour name (`dev` / `staging` / `prod`).
  final String name;

  /// Base URL for the remote API in this flavour.
  final String apiBaseUrl;

  /// Lowest [LogLevel] emitted by the [AppLogger] in this flavour.
  final LogLevel minLogLevel;
}
