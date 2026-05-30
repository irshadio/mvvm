import 'package:mvvm/app/run_app.dart';
import 'package:mvvm/core/config/app_environment.dart';

/// Default (flavour-less) entrypoint. Resolves the flavour from the `APP_ENV`
/// dart-define (default: `dev`) and delegates to the shared [runMvvmApp].
///
/// For a specific Android/iOS flavour use the dedicated entrypoints —
/// `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart` — which
/// pair with `--flavor`. See `docs/FLAVORS.md`.
void main() => runMvvmApp(AppEnvironment.fromEnv());
