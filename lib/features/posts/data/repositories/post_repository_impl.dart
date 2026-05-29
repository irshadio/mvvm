import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/features/posts/data/dtos/post_dto.dart';
import 'package:mvvm/features/posts/data/sources/post_local_data_source.dart';
import 'package:mvvm/features/posts/data/sources/post_remote_data_source.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';

/// Concrete [PostRepository]: maps DTOs -> entities, write-through caches
/// successful fetches, and serves the cache when the device is offline.
class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({required this.remote, required this.local});

  final PostRemoteDataSource remote;
  final PostLocalDataSource local;

  @override
  Future<Either<Failure, List<Post>>> getPosts() async {
    final result = await remote.fetchPosts();
    return result.match(
      (failure) async {
        // Offline fallback: serve cache when there is no connectivity.
        if (failure is NoConnectionFailure) {
          final cached = await local.readPosts();
          if (cached.isNotEmpty) {
            return right<Failure, List<Post>>(
              cached.map((dto) => dto.toEntity()).toList(),
            );
          }
        }
        return left<Failure, List<Post>>(failure);
      },
      (dtos) async {
        await local.writePosts(dtos);
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
}
