import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/features/posts/data/dtos/post_dto.dart';
import 'package:mvvm/features/posts/data/sources/post_remote_data_source.dart';
import 'package:remote_client/remote_client.dart' as rc;

/// Minimal fake `RemoteClient` whose `get` returns a canned response; every
/// other member throws via `noSuchMethod` (the data source only calls `get`).
class _FakeRemoteClient implements rc.RemoteClient {
  _FakeRemoteClient(this.response);

  final rc.Either<rc.Failure, rc.BaseResponse<List<PostDto>>> response;

  @override
  Future<rc.Either<rc.Failure, rc.BaseResponse<T>>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(Object?)? fromJson,
    Object? cancelToken,
    Object? options,
    Object? timeout,
  }) async => response as rc.Either<rc.Failure, rc.BaseResponse<T>>;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

rc.Either<rc.Failure, rc.BaseResponse<List<PostDto>>> _ok(
  List<PostDto>? data,
) => rc.Right<rc.Failure, rc.BaseResponse<List<PostDto>>>(
  rc.BaseResponse<List<PostDto>>(statusCode: 200, success: true, data: data),
);

void main() {
  const dto = PostDto(id: 1, userId: 1, title: 'T', body: 'B');

  PostRemoteDataSource sourceWith(
    rc.Either<rc.Failure, rc.BaseResponse<List<PostDto>>> response,
  ) => PostRemoteDataSourceImpl(_FakeRemoteClient(response));

  test('null data becomes a Failure, not an empty list', () async {
    // remote_client swallows a throwing fromJson into `data: null` on a 2xx;
    // the data source must surface that, not mask it as a successful page.
    final result = await sourceWith(_ok(null)).fetchPosts();
    result.match(
      (failure) => expect(failure, isA<UnexpectedFailure>()),
      (_) => fail('expected a Left(UnexpectedFailure)'),
    );
  });

  test('a genuinely empty list stays a successful empty list', () async {
    final result = await sourceWith(_ok(<PostDto>[])).fetchPosts();
    result.match(
      (_) => fail('expected a Right'),
      (list) => expect(list, isEmpty),
    );
  });

  test('a populated list is returned as data', () async {
    final result = await sourceWith(_ok(<PostDto>[dto])).fetchPosts();
    result.match(
      (_) => fail('expected a Right'),
      (list) => expect(list, <PostDto>[dto]),
    );
  });
}
