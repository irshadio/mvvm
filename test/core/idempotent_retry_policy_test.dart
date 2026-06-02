import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm/core/network/idempotent_retry_policy.dart';

DioException _error(
  String method, {
  DioExceptionType type = DioExceptionType.connectionError,
  int? statusCode,
}) {
  final options = RequestOptions(path: '/posts', method: method);
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response<dynamic>(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  bool retries(DioException e) => idempotentRetryPolicy.shouldRetry!(e);

  group('idempotent methods retry on transient failures', () {
    test('GET retries on a connection error', () {
      expect(retries(_error('GET')), isTrue);
    });

    test('GET retries on a 503', () {
      expect(
        retries(
          _error('GET', type: DioExceptionType.badResponse, statusCode: 503),
        ),
        isTrue,
      );
    });

    test('PUT retries (idempotent write)', () {
      expect(retries(_error('PUT')), isTrue);
    });

    test('DELETE retries (idempotent write)', () {
      expect(retries(_error('DELETE')), isTrue);
    });
  });

  group('non-idempotent writes are NEVER retried', () {
    test('POST does not retry on a connection error', () {
      expect(retries(_error('POST')), isFalse);
    });

    test('POST does not retry on a 503', () {
      expect(
        retries(
          _error('POST', type: DioExceptionType.badResponse, statusCode: 503),
        ),
        isFalse,
      );
    });

    test('PATCH does not retry', () {
      expect(retries(_error('PATCH')), isFalse);
    });
  });

  group('non-retryable conditions are not retried even for GET', () {
    test('GET does not retry on a 404', () {
      expect(
        retries(
          _error('GET', type: DioExceptionType.badResponse, statusCode: 404),
        ),
        isFalse,
      );
    });

    test('GET does not retry on a cancellation', () {
      expect(retries(_error('GET', type: DioExceptionType.cancel)), isFalse);
    });

    test('GET does not retry on a bad certificate', () {
      expect(
        retries(_error('GET', type: DioExceptionType.badCertificate)),
        isFalse,
      );
    });
  });
}
