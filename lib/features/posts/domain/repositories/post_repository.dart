import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/features/posts/domain/entities/create_post_input.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_repository.g.dart';

/// Contract for posts data access. ViewModels depend on this abstraction, never
/// on a concrete implementation or a data source.
abstract interface class PostRepository {
  /// A page of posts (1-based, [page]/[limit]). Falls back to the local cache
  /// when offline on the first page.
  Future<Either<Failure, List<Post>>> getPosts({int page, int limit});

  /// A single post by id.
  Future<Either<Failure, Post>> getPost(int id);

  /// Creates a post, returning the created entity (server-assigned id).
  Future<Either<Failure, Post>> createPost(CreatePostInput input);
}

/// Bound to `PostRepositoryImpl` in `posts_overrides.dart`.
@riverpod
PostRepository postRepository(Ref ref) => throw UnimplementedError(
  'postRepositoryProvider must be overridden — see posts_overrides.dart.',
);
