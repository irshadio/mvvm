import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/error/failure_mapper.dart';
import 'package:remote_client/remote_client.dart' as rc;

// Guards the single transport->app error boundary: every `rc.Failure` subtype
// must map to the intended app `Failure`. A new rc case makes the mapper fail
// to compile; this locks the existing mappings.
void main() {
  test('NoInternet -> NoConnectionFailure', () {
    expect(mapRemoteFailure(const rc.NoInternet()), isA<NoConnectionFailure>());
  });

  test('ConnectionError / BadCertificate -> NetworkFailure', () {
    expect(
      mapRemoteFailure(const rc.ConnectionError(message: 'down')),
      isA<NetworkFailure>().having((f) => f.message, 'message', 'down'),
    );
    expect(
      mapRemoteFailure(const rc.BadCertificate()),
      isA<NetworkFailure>(),
    );
  });

  test('timeouts -> TimeoutFailure', () {
    const failures = <rc.Failure>[
      rc.ConnectionTimeout(),
      rc.SendTimeout(),
      rc.ReceiveTimeout(),
    ];
    for (final failure in failures) {
      expect(mapRemoteFailure(failure), isA<TimeoutFailure>());
    }
  });

  test('Unauthorized -> UnauthorizedFailure', () {
    expect(
      mapRemoteFailure(const rc.Unauthorized()),
      isA<UnauthorizedFailure>(),
    );
  });

  test('BadRequest -> ValidationFailure', () {
    expect(mapRemoteFailure(const rc.BadRequest()), isA<ValidationFailure>());
  });

  test('server-side statuses -> ServerFailure', () {
    const failures = <rc.Failure>[
      rc.NotFound(),
      rc.BadResponse(),
      rc.InternalServerError(),
      rc.ServiceUnavailable(),
    ];
    for (final failure in failures) {
      expect(mapRemoteFailure(failure), isA<ServerFailure>());
    }
  });

  test('Cancelled -> CancelledFailure', () {
    expect(mapRemoteFailure(const rc.Cancelled()), isA<CancelledFailure>());
  });

  test('Unexpected -> UnexpectedFailure', () {
    expect(mapRemoteFailure(const rc.Unexpected()), isA<UnexpectedFailure>());
  });
}
