import 'package:mvvm/app/run_app.dart';
import 'package:mvvm/core/config/app_environment.dart';

/// Staging flavour entrypoint. Run with:
///   flutter run --flavor staging -t lib/main_staging.dart --dart-define=APP_ENV=staging
void main() => runMvvmApp(AppEnvironment.staging);
