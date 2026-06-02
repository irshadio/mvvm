import 'package:mvvm/core/storage/local_store.dart';
import 'package:mvvm/features/posts/data/dtos/post_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_local_data_source.g.dart';

/// Local cache for posts, backed by the sembast [LocalStore].
abstract interface class PostLocalDataSource {
  Future<List<PostDto>> readPosts();
  Future<void> writePosts(List<PostDto> posts);
}

class PostLocalDataSourceImpl implements PostLocalDataSource {
  PostLocalDataSourceImpl(this._store);

  final LocalStore _store;
  static const String _storeName = 'posts';

  @override
  Future<List<PostDto>> readPosts() async {
    final records = await _store.readAll(_storeName);
    return records.map(PostDto.fromJson).toList();
  }

  @override
  // Replace, not upsert: the cache is the page-1 snapshot, so a post removed at
  // the source must not linger offline. See LocalStore.replaceAll.
  Future<void> writePosts(List<PostDto> posts) => _store.replaceAll(
    _storeName,
    <String, Map<String, Object?>>{
      for (final post in posts) post.id.toString(): post.toJson(),
    },
  );
}

/// Bound to `PostLocalDataSourceImpl` in `posts_overrides.dart`.
@riverpod
PostLocalDataSource postLocalDataSource(Ref ref) => throw UnimplementedError(
  'postLocalDataSourceProvider must be overridden — see posts_overrides.dart.',
);
