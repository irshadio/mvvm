/// Centralised, compile-time application configuration.
///
/// For multiple environments (dev / staging / prod), read a
/// `--dart-define=ENV=...` value here and branch, or split into Flutter
/// flavors. Kept as simple `const`s to start — "don't make complicated".
abstract final class AppConfig {
  /// Base URL for the remote API. The example feature targets the public,
  /// stable JSONPlaceholder API to prove the template end-to-end.
  static const String apiBaseUrl = 'https://jsonplaceholder.typicode.com';

  /// File name for the on-device sembast database.
  static const String databaseName = 'mvvm_app.db';
}
