import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mvvm/core/config/app_config.dart';
import 'package:mvvm/core/config/app_environment.dart';
import 'package:mvvm/core/error/error_reporter.dart';
import 'package:mvvm/core/logging/app_logger.dart';
import 'package:mvvm/core/network/connectivity.dart';
import 'package:mvvm/core/network/remote_client_provider.dart';
import 'package:mvvm/core/network/token_provider.dart';
import 'package:mvvm/core/network/unauthorized_handler.dart';
import 'package:mvvm/core/storage/local_store.dart';
import 'package:mvvm/core/storage/secure_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:remote_client/remote_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast_io.dart';

/// The composition root.
///
/// Opens async infrastructure (the sembast database) and binds every abstract
/// contract provider to its concrete implementation via `ProviderScope`
/// overrides. `app/run_app.dart` awaits this before `runApp`, so by the first
/// frame every contract is wired. This is the single, authoritative place to
/// read what is wired to what.
///
/// [env] selects the flavour-specific config (e.g. the API base URL). [logger]
/// and [reporter] are created by the caller (`run_app.dart`) so the global
/// error handlers can share the same instances; they are bound here so features
/// can `ref.watch` them too.
///
/// Each feature contributes its own overrides (a `List<Override>` exposed from
/// the feature) — aggregate them with these in `run_app.dart`.
///
/// Tests build their own override lists to swap fakes for any contract.
Future<List<Override>> buildCoreOverrides({
  required AppEnvironment env,
  required AppLogger logger,
  required ErrorReporter reporter,
}) async {
  // --- Async infrastructure init (must be ready before first frame) ---
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, AppConfig.databaseName);
  final db = await databaseFactoryIo.openDatabase(dbPath);

  return <Override>[
    // --- Observability (instances created in run_app.dart) ---
    appLoggerProvider.overrideWith((ref) => logger),
    errorReporterProvider.overrideWith((ref) => reporter),

    // --- Storage ---
    secureStoreProvider.overrideWith(
      (ref) => SecureStoreImpl(
        // Hardened secure storage. iOS: tokens are accessible only after the
        // first unlock and are bound to THIS device (not synced to iCloud
        // Keychain or restored to a new device). Android: v10's default already
        // uses AES-GCM data encryption with RSA-OAEP key wrapping in the
        // KeyStore (the old `encryptedSharedPreferences` flag is deprecated and
        // ignored), so no extra Android options are needed.
        const FlutterSecureStorage(
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        ),
      ),
    ),
    localStoreProvider.overrideWith((ref) => LocalStoreImpl(db)),

    // --- Connectivity (real DNS-probe reachability) ---
    connectivityServiceProvider.overrideWith(
      (ref) => ConnectivityServiceImpl(),
    ),

    // --- Auth ---
    tokenProviderProvider.overrideWith(
      (ref) => SecureTokenProvider(ref.watch(secureStoreProvider)),
    ),
    unauthorizedHandlerProvider.overrideWith(
      (ref) => AppUnauthorizedHandler(ref.watch(secureStoreProvider)),
    ),

    // --- Remote client (composes auth + retry + response parsing) ---
    remoteClientProvider.overrideWith(
      (ref) => RemoteClientFactory.builder()
          .baseUrl(env.config.apiBaseUrl)
          .withAuth(
            tokenProvider: ref.watch(tokenProviderProvider),
            unauthorizedHandler: ref.watch(unauthorizedHandlerProvider),
          )
          .withRetry(RetryPolicy.defaultPolicy)
          // JSONPlaceholder returns UNWRAPPED JSON (no {success, data}
          // envelope), so parse the body directly. For an API that wraps
          // responses, drop this to use the default DefaultResponseParser.
          .withResponseParser(const DirectResponseParser())
          // ignore: avoid_redundant_argument_values kDebugMode is not a literal
          .enableLogging(enabled: kDebugMode)
          .build(),
    ),
  ];
}
