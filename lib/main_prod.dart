import 'package:mvvm/app/run_app.dart';
import 'package:mvvm/core/config/app_environment.dart';

/// Production flavour entrypoint. Run with:
///   flutter run --flavor prod -t lib/main_prod.dart --dart-define=APP_ENV=prod
void main() => runMvvmApp(AppEnvironment.prod);
