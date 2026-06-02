import 'package:dio/dio.dart';
import 'package:remote_client/remote_client.dart';

/// HTTP methods that are safe to retry because they are idempotent — repeating
/// them has the same effect as a single call. `POST` and `PATCH` are
/// deliberately absent: retrying them after a timeout or 5xx can DUPLICATE a
/// write the server already applied (e.g. create the same post twice).
const Set<String> _idempotentMethods = <String>{
  'GET',
  'HEAD',
  'OPTIONS',
  'PUT',
  'DELETE',
};

/// `remote_client` retry policy with the same triggers as
/// [RetryPolicy.defaultPolicy] (connection errors, timeouts, and the
/// `{500, 502, 503, 504}` server errors) but gated to **idempotent methods
/// only**, so reads stay resilient to transient failures while writes are never
/// silently retried into duplicates.
///
/// `maxRetries` / backoff / jitter still come from the [RetryPolicy] defaults;
/// `shouldRetry` only replaces the *which-errors* decision (the interceptor
/// still enforces `retryCount >= maxRetries` and the cancel short-circuit).
const RetryPolicy idempotentRetryPolicy = RetryPolicy(
  shouldRetry: _shouldRetryIdempotent,
);

bool _shouldRetryIdempotent(Object? error) {
  if (error is! DioException) return false;
  if (!_idempotentMethods.contains(error.requestOptions.method.toUpperCase())) {
    return false;
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError ||
    DioExceptionType.unknown => true,
    DioExceptionType.badResponse => const <int>{
      500,
      502,
      503,
      504,
    }.contains(error.response?.statusCode),
    DioExceptionType.badCertificate || DioExceptionType.cancel => false,
  };
}
