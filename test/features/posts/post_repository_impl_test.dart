import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/features/posts/data/dtos/post_dto.dart';
import 'package:mvvm/features/posts/data/repositories/post_repository_impl.dart';
import 'package:mvvm/features/posts/data/sources/post_local_data_source.dart';
import 'package:mvvm/features/posts/data/sources/post_remote_data_source.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';

class _FakeRemote implements PostRemoteDataSource {
  _FakeRemote(this.result, {this.single});

  final Either<Failure, List<PostDto>> result;
  final Either<Failure, PostDto>? single;

  @override
  Future<Either<Failure, List<PostDto>>> fetchPosts() async => result;

  @override
  Future<Either<Failure, PostDto>> fetchPost(int id) async =>
      single ?? (throw UnimplementedError());
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

  test('offline cache is served in numeric id order, not key order', () async {
    // The cache returns records in lexicographic key order ("1","10","2"…);
    // the repository must re-sort numerically so ids ascend like the server.
    const unordered = <PostDto>[
      PostDto(id: 10, userId: 1, title: 'ten', body: 'b'),
      PostDto(id: 2, userId: 1, title: 'two', body: 'b'),
      PostDto(id: 1, userId: 1, title: 'one', body: 'b'),
    ];
    final repo = PostRepositoryImpl(
      remote: _FakeRemote(
        left<Failure, List<PostDto>>(const Failure.noConnection()),
      ),
      local: _FakeLocal(List<PostDto>.of(unordered)),
    );

    final result = await repo.getPosts();

    result.match(
      (failure) => fail('expected Right, got Left($failure)'),
      (posts) => expect(posts.map((p) => p.id), <int>[1, 2, 10]),
    );
  });

  test('getPost maps the remote DTO to an entity', () async {
    final repo = PostRepositoryImpl(
      remote: _FakeRemote(
        right<Failure, List<PostDto>>(const <PostDto>[]),
        single: right<Failure, PostDto>(dto),
      ),
      local: _FakeLocal(),
    );

    final result = await repo.getPost(1);

    result.match(
      (failure) => fail('expected Right, got Left($failure)'),
      (loaded) => expect(loaded, post),
    );
  });

  test('getPost propagates a remote failure', () async {
    const failure = Failure.server(statusCode: 404, message: 'missing');
    final repo = PostRepositoryImpl(
      remote: _FakeRemote(
        right<Failure, List<PostDto>>(const <PostDto>[]),
        single: left<Failure, PostDto>(failure),
      ),
      local: _FakeLocal(),
    );

    final result = await repo.getPost(99);

    result.match(
      (f) => expect(f, failure),
      (loaded) => fail('expected Left, got Right($loaded)'),
    );
  });
}
