import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:remote_client/remote_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';
import 'token_provider.dart';
import 'unauthorized_handler.dart';

part 'remote_client_provider.g.dart';

/// The single configured [RemoteClient] for the app. Every remote data source
/// depends on this provider; no feature constructs its own client.
///
/// Auth, retry, logging and response parsing are wired here once.
@riverpod
RemoteClient remoteClient(Ref ref) {
  return RemoteClientFactory.builder()
      .baseUrl(AppConfig.apiBaseUrl)
      .withAuth(
        tokenProvider: ref.watch(tokenProviderProvider),
        unauthorizedHandler: ref.watch(unauthorizedHandlerProvider),
      )
      .withRetry(RetryPolicy.defaultPolicy)
      // JSONPlaceholder returns UNWRAPPED JSON (no {success, data} envelope),
      // so parse the body directly. If your API wraps responses in an envelope,
      // remove this line to fall back to the default DefaultResponseParser.
      .withResponseParser(const DirectResponseParser())
      .enableLogging(enabled: kDebugMode)
      .build();
}
