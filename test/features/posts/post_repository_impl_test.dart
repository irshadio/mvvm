import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/features/posts/data/dtos/post_dto.dart';
import 'package:mvvm/features/posts/data/repositories/post_repository_impl.dart';
import 'package:mvvm/features/posts/data/sources/post_local_data_source.dart';
import 'package:mvvm/features/posts/data/sources/post_remote_data_source.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';

class _FakeRemote implements PostRemoteDataSource {
  _FakeRemote(this.result);

  final Either<Failure, List<PostDto>> result;

  @override
  Future<Either<Failure, List<PostDto>>> fetchPosts() async => result;

  @override
  Future<Either<Failure, PostDto>> fetchPost(int id) async =>
      throw UnimplementedError();
}

class _FakeLocal implements PostLocalDataSource {
  _FakeLocal([this.cache = const []]);

  List<PostDto> cache;

  @override
  Future<List<PostDto>> readPosts() async => cache;

  @override
  Future<void> writePosts(List<PostDto> posts) async => cache = posts;
}

void main() {
  const dto = PostDto(id: 1, userId: 1, title: 'T', body: 'B');
  const post = Post(id: 1, title: 'T', body: 'B');

  test('remote success maps to entities and caches', () async {
    final local = _FakeLocal();
    final repo = PostRepositoryImpl(
      remote: _FakeRemote(right<Failure, List<PostDto>>(<PostDto>[dto])),
      local: local,
    );

    final result = await repo.getPosts();

    result.match(
      (failure) => fail('expected Right, got Left($failure)'),
      (posts) => expect(posts, <Post>[post]),
    );
    expect(local.cache, <PostDto>[dto]);
  });

  test('offline with a cache serves the cached entities', () async {
    final repo = PostRepositoryImpl(
      remote: _FakeRemote(
        left<Failure, List<PostDto>>(const Failure.noConnection()),
      ),
      local: _FakeLocal(<PostDto>[dto]),
    );

    final result = await repo.getPosts();

    result.match(
      (failure) => fail('expected Right, got Left($failure)'),
      (posts) => expect(posts, <Post>[post]),
    );
  });

  test('offline with an empty cache returns the failure', () async {
    final repo = PostRepositoryImpl(
      remote: _FakeRemote(
        left<Failure, List<PostDto>>(const Failure.noConnection()),
      ),
      local: _FakeLocal(),
    );

    final result = await repo.getPosts();

    result.match(
      (failure) => expect(failure, const Failure.noConnection()),
      (posts) => fail('expected Left, got Right($posts)'),
    );
  });
}
