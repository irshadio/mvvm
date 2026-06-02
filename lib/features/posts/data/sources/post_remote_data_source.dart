import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/error/failure_mapper.dart';
import 'package:mvvm/features/posts/data/dtos/post_dto.dart';
import 'package:mvvm/features/posts/domain/entities/create_post_input.dart';
import 'package:remote_client/remote_client.dart' as rc;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_remote_data_source.g.dart';

/// Remote source for posts. ALL `rc.*` (remote_client) types are confined to
/// this implementation; it returns app-typed `Either<Failure, ...>` so the
/// repository and everything above it never see a transport type.
abstract interface class PostRemoteDataSource {
  Future<Either<Failure, List<PostDto>>> fetchPosts({int page, int limit});
  Future<Either<Failure, PostDto>> fetchPost(int id);
  Future<Either<Failure, PostDto>> createPost(CreatePostInput input);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  PostRemoteDataSourceImpl(this._client);

  final rc.RemoteClient _client;

  @override
  Future<Either<Failure, List<PostDto>>> fetchPosts({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _client.get<List<PostDto>>(
      '/posts',
      queryParams: <String, dynamic>{'_page': page, '_limit': limit},
      fromJson: (json) => (json! as List<dynamic>)
          .map((e) => PostDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return result.fold<Either<Failure, List<PostDto>>>(
      (failure) => left(mapRemoteFailure(failure)),
      (response) {
        // `remote_client`'s parser SWALLOWS a throwing `fromJson` and yields
        // `data == null` on a 2xx, so null here means "undecodable body", NOT
        // "empty list" (a genuinely empty page decodes to a non-null `[]`).
        // Surface it as a failure rather than masking a broken response as a
        // successful empty list.
        final data = response.data;
        if (data == null) {
          return left(
            const Failure.unexpected(message: 'Failed to decode response'),
          );
        }
        return right(data);
      },
    );
  }

  @override
  Future<Either<Failure, PostDto>> fetchPost(int id) async {
    final result = await _client.get<PostDto>(
      '/posts/$id',
      fromJson: (json) => PostDto.fromJson(json! as Map<String, dynamic>),
    );
    return result.fold<Either<Failure, PostDto>>(
      (failure) => left(mapRemoteFailure(failure)),
      (response) => response.data != null
          ? right(response.data!)
          : left(const Failure.unexpected(message: 'Empty response body')),
    );
  }

  @override
  Future<Either<Failure, PostDto>> createPost(CreatePostInput input) async {
    final result = await _client.post<PostDto>(
      '/posts',
      data: <String, dynamic>{
        'title': input.title,
        'body': input.body,
        'userId': input.userId,
      },
      fromJson: (json) => PostDto.fromJson(json! as Map<String, dynamic>),
    );
    return result.fold<Either<Failure, PostDto>>(
      (failure) => left(mapRemoteFailure(failure)),
      (response) => response.data != null
          ? right(response.data!)
          : left(const Failure.unexpected(message: 'Empty response body')),
    );
  }
}

/// Bound to `PostRemoteDataSourceImpl` in `posts_overrides.dart`.
@riverpod
PostRemoteDataSource postRemoteDataSource(Ref ref) => throw UnimplementedError(
  'postRemoteDataSourceProvider must be overridden — see posts_overrides.dart.',
);
