import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm/core/storage/local_store.dart';
import 'package:mvvm/features/posts/data/dtos/post_dto.dart';
import 'package:mvvm/features/posts/data/sources/post_local_data_source.dart';
import 'package:sembast/sembast_memory.dart';

/// Exercises the real `LocalStoreImpl` (over an in-memory sembast db) through
/// the posts cache, proving the snapshot is *replaced*, not upserted — a post
/// removed at the source must not linger offline.
void main() {
  late PostLocalDataSource source;

  setUp(() async {
    // A fresh isolated in-memory factory per test (no shared state).
    final db = await newDatabaseFactoryMemory().openDatabase('test.db');
    source = PostLocalDataSourceImpl(LocalStoreImpl(db));
  });

  PostDto dto(int id) => PostDto(id: id, userId: 1, title: 'T$id', body: 'B');

  Future<Set<int>> cachedIds() async =>
      (await source.readPosts()).map((p) => p.id).toSet();

  test('writePosts round-trips the cached posts', () async {
    await source.writePosts(<PostDto>[dto(1), dto(2), dto(3)]);
    expect(await cachedIds(), <int>{1, 2, 3});
  });

  test('writePosts evicts posts dropped from the new snapshot', () async {
    await source.writePosts(<PostDto>[dto(1), dto(2), dto(3)]);
    // Second snapshot omits id 3 (removed at the source).
    await source.writePosts(<PostDto>[dto(1), dto(2)]);
    expect(await cachedIds(), <int>{1, 2});
  });
}
