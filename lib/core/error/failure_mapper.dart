import 'package:remote_client/remote_client.dart' as rc;

import 'failure.dart';

/// Translates a transport-layer [rc.Failure] from `remote_client` into the
/// app-wide [Failure] vocabulary.
///
/// This is the ONLY place `remote_client`'s failure type is interpreted.
/// Repositories call it so that no `rc.*` type ever escapes the `data/` layer
/// — every higher layer speaks only the app [Failure] union.
///
/// The `switch` is exhaustive over `rc.Failure`'s sealed subtypes: if a future
/// `remote_client` upgrade adds a case, this stops compiling until it is mapped.
Failure mapRemoteFailure(rc.Failure failure) {
  final int statusCode = failure.response?.statusCode ?? 0;
  final String message = failure.errorMessage;

  return switch (failure) {
    rc.NoInternet() => const Failure.noConnection(),
    rc.ConnectionError() || rc.BadCertificate() => Failure.network(message: message),
    rc.ConnectionTimeout() ||
    rc.SendTimeout() ||
    rc.ReceiveTimeout() => Failure.timeout(message: message),
    rc.Unauthorized() => Failure.unauthorized(message: message),
    rc.BadRequest() => Failure.validation(message: message),
    rc.NotFound() ||
    rc.BadResponse() ||
    rc.InternalServerError() ||
    rc.ServiceUnavailable() =>
      Failure.server(statusCode: statusCode, message: message),
    rc.Cancelled() => Failure.cancelled(message: message),
    rc.Unexpected() => Failure.unexpected(message: message),
  };
}
