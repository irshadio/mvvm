import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// The single, app-wide error vocabulary.
///
/// Every layer that can fail returns a [Failure] on the `Left` of an `Either`.
/// `remote_client` failures (and any Dio/socket errors) are translated into
/// this union at the repository boundary (see `failure_mapper.dart`), so no
/// `remote_client` or transport type ever leaks past the `data/` layer.
///
/// Because every case carries a `message`, `failure.message` is always readable
/// without pattern-matching; switch only when you need case-specific fields.
@freezed
sealed class Failure with _$Failure {
  /// Transport-level problem (socket, DNS, TLS) that is not a clean HTTP
  /// status.
  const factory Failure.network({required String message}) = NetworkFailure;

  /// Server returned a non-2xx HTTP status.
  const factory Failure.server({
    required int statusCode,
    required String message,
  }) = ServerFailure;

  /// The request exceeded its timeout budget.
  const factory Failure.timeout({
    @Default('The request timed out') String message,
  }) = TimeoutFailure;

  /// No real internet reachability. Maps to `ViewState.noInternet`.
  const factory Failure.noConnection({
    @Default('No internet connection') String message,
  }) = NoConnectionFailure;

  /// Authentication / authorization failed (e.g. 401/403).
  const factory Failure.unauthorized({
    @Default('Your session has expired') String message,
  }) = UnauthorizedFailure;

  /// The request was cancelled before completing.
  const factory Failure.cancelled({
    @Default('The request was cancelled') String message,
  }) = CancelledFailure;

  /// Local persistence (sembast / secure storage) failed.
  const factory Failure.cache({required String message}) = CacheFailure;

  /// Input or business-rule validation failed.
  const factory Failure.validation({required String message}) =
      ValidationFailure;

  /// Anything we did not explicitly anticipate.
  const factory Failure.unexpected({
    @Default('Something went wrong') String message,
  }) = UnexpectedFailure;
}
