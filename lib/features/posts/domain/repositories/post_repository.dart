import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_repository.g.dart';

/// Contract for posts data access. ViewModels depend on this abstraction, never
/// on a concrete implementation or a data source.
abstract interface class PostRepository {
  /// All posts. Falls back to the local cache when offline.
  Future<Either<Failure, List<Post>>> getPosts();

  /// A single post by id.
  Future<Either<Failure, Post>> getPost(int id);
}

/// Bound to `PostRepositoryImpl` in `posts_overrides.dart`.
@riverpod
PostRepository postRepository(Ref ref) => throw UnimplementedError(
  'postRepositoryProvider must be overridden — see posts_overrides.dart.',
);
