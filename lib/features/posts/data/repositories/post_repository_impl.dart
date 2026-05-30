import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/features/posts/data/dtos/post_dto.dart';
import 'package:mvvm/features/posts/data/sources/post_local_data_source.dart';
import 'package:mvvm/features/posts/data/sources/post_remote_data_source.dart';
import 'package:mvvm/features/posts/domain/entities/create_post_input.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';

/// Concrete [PostRepository]: maps DTOs -> entities, write-through caches
/// successful fetches, and serves the cache when the device is offline.
class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({required this.remote, required this.local});

  final PostRemoteDataSource remote;
  final PostLocalDataSource local;

  @override
  Future<Either<Failure, List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await remote.fetchPosts(page: page, limit: limit);
    return result.match(
      (failure) async {
        // Offline fallback policy: the cache is served ONLY for
        // `NoConnectionFailure`, and ONLY for the first page (the cache holds
        // the page-1 snapshot). A server/timeout error deliberately surfaces
        // rather than masking a live failure with stale data.
        if (failure is NoConnectionFailure && page == 1) {
          // The cache is keyed by `id.toString()`, so the store returns it in
          // lexicographic key order ("1","10","2"…). Re-sort numerically so the
          // offline list matches the server's id order. Copy first — the source
          // list may be unmodifiable.
          final cached = <PostDto>[...await local.readPosts()]
            ..sort((a, b) => a.id.compareTo(b.id));
          if (cached.isNotEmpty) {
            return right<Failure, List<Post>>(
              cached.map((dto) => dto.toEntity()).toList(),
            );
          }
        }
        return left<Failure, List<Post>>(failure);
      },
      (dtos) async {
        // Cache only the first page as the offline snapshot.
        if (page == 1) await local.writePosts(dtos);
        return right<Failure, List<Post>>(
          dtos.map((dto) => dto.toEntity()).toList(),
        );
      },
    );
  }

  @override
  Future<Either<Failure, Post>> getPost(int id) async {
    final result = await remote.fetchPost(id);
    return result.map((dto) => dto.toEntity());
  }

  @override
  Future<Either<Failure, Post>> createPost(CreatePostInput input) async {
    final result = await remote.createPost(input);
    return result.map((dto) => dto.toEntity());
  }
}
