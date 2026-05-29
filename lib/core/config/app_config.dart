import 'package:envied/envied.dart';

part 'app_config.g.dart';

/// Type-safe application configuration, generated from the `.env` file by
/// `envied` at build time. Run `dart run build_runner build` to (re)generate
/// `app_config.g.dart`.
///
/// For real secrets (API keys, etc.) add `@EnviedField(obfuscate: true)` so the
/// value is not stored as a plain string in the binary, and remove `.env` from
/// version control.
@Envied(path: '.env')
abstract class AppConfig {
  /// Base URL for the remote API (from `.env` `API_BASE_URL`).
  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _AppConfig.apiBaseUrl;

  /// File name for the on-device sembast database (not environment-specific).
  static const String databaseName = 'mvvm_app.db';
}
