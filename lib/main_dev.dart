import 'package:mvvm/app/run_app.dart';
import 'package:mvvm/core/config/app_environment.dart';

/// Dev flavour entrypoint. Run with:
///   flutter run --flavor dev -t lib/main_dev.dart --dart-define=APP_ENV=dev
void main() => runMvvmApp(AppEnvironment.dev);
