import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:mvvm/features/posts/domain/entities/create_post_input.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';
import 'package:mvvm/features/posts/presentation/view_model/posts_view_model.dart';

/// Stub repository whose result can be swapped between calls (to model a
/// refresh that succeeds then fails).
class _StubRepository implements PostRepository {
  _StubRepository(this.result);

  Either<Failure, List<Post>> result;

  @override
  Future<Either<Failure, List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
  }) => Future<Either<Failure, List<Post>>>.value(result);

  @override
  Future<Either<Failure, Post>> getPost(int id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Post>> createPost(CreatePostInput input) async =>
      throw UnimplementedError();
}

/// Repository that serves a different list per requested page.
class _PagingRepository implements PostRepository {
  _PagingRepository(this.pages);

  final Map<int, List<Post>> pages;

  @override
  Future<Either<Failure, List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
  }) => Future<Either<Failure, List<Post>>>.value(
    right<Failure, List<Post>>(pages[page] ?? const <Post>[]),
  );

  @override
  Future<Either<Failure, Post>> getPost(int id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Post>> createPost(CreatePostInput input) async =>
      throw UnimplementedError();
}

/// Counts calls and never completes its futures — lets a test hold the
/// ViewModel in the `loading` state to exercise the in-flight guards.
class _CountingHangingRepository implements PostRepository {
  int calls = 0;

  @override
  Future<Either<Failure, List<Post>>> getPosts({int page = 1, int limit = 20}) {
    calls++;
    return Completer<Either<Failure, List<Post>>>().future; // never completes
  }

  @override
  Future<Either<Failure, Post>> getPost(int id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Post>> createPost(CreatePostInput input) async =>
      throw UnimplementedError();
}

List<Post> _posts(int from, int count) => List<Post>.generate(
  count,
  (i) => Post(id: from + i, title: 'T${from + i}', body: 'B'),
);

void main() {
  const posts = <Post>[Post(id: 1, title: 'T', body: 'B')];

  ProviderContainer containerWith(_StubRepository repo) {
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWith((ref) => repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('build() starts idle', () {
    final container = containerWith(
      _StubRepository(right<Failure, List<Post>>(posts)),
    );
    expect(
      container.read(postsViewModelProvider),
      const ViewState<List<Post>>.idle(),
    );
  });

  test('load() success maps to data', () async {
    final container = containerWith(
      _StubRepository(right<Failure, List<Post>>(posts)),
    );
    await container.read(postsViewModelProvider.notifier).load();
    expect(
      container.read(postsViewModelProvider),
      const ViewState<List<Post>>.data(posts),
    );
  });

  test('load() no connection maps to noInternet', () async {
    final container = containerWith(
      _StubRepository(left<Failure, List<Post>>(const Failure.noConnection())),
    );
    await container.read(postsViewModelProvider.notifier).load();
    expect(
      container.read(postsViewModelProvider),
      const ViewState<List<Post>>.noInternet(),
    );
  });

  test('a failed refresh keeps the previously loaded data', () async {
    final repo = _StubRepository(right<Failure, List<Post>>(posts));
    final container = containerWith(repo);
    final notifier = container.read(postsViewModelProvider.notifier);

    await notifier.load(); // success -> data(posts)
    repo.result = left<Failure, List<Post>>(
      const Failure.server(statusCode: 500, message: 'boom'),
    );
    await notifier.load(); // failure -> error, but data is retained

    final state = container.read(postsViewModelProvider);
    expect(state, isA<ViewError<List<Post>>>());
    expect(state.dataOrNull, posts);
  });

  ProviderContainer containerFor(PostRepository repo) {
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWith((ref) => repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('loadMore appends the next page and tracks hasMore', () async {
    // A full first page (20) implies more; a short second page (5) is the end.
    final container = containerFor(
      _PagingRepository(<int, List<Post>>{1: _posts(1, 20), 2: _posts(21, 5)}),
    );
    final notifier = container.read(postsViewModelProvider.notifier);

    await notifier.load();
    expect(container.read(postsViewModelProvider).dataOrNull, hasLength(20));
    expect(notifier.hasMore, isTrue);

    await notifier.loadMore();
    expect(container.read(postsViewModelProvider).dataOrNull, hasLength(25));
    expect(notifier.hasMore, isFalse);

    // The last page is in — loadMore is now a no-op.
    await notifier.loadMore();
    expect(container.read(postsViewModelProvider).dataOrNull, hasLength(25));
  });

  test('load() resets pagination back to the first page', () async {
    final container = containerFor(
      _PagingRepository(<int, List<Post>>{1: _posts(1, 20), 2: _posts(21, 5)}),
    );
    final notifier = container.read(postsViewModelProvider.notifier);

    await notifier.load();
    await notifier.loadMore(); // 25 items, hasMore false
    await notifier.load(); // reload -> first page only

    expect(container.read(postsViewModelProvider).dataOrNull, hasLength(20));
    expect(notifier.hasMore, isTrue);
  });

  test('load() is a no-op while a request is already in flight', () async {
    // Guards against a pull-to-refresh racing an in-flight load — which would
    // otherwise apply pagination bookkeeping out of order (see load()).
    final repo = _CountingHangingRepository();
    final container = containerFor(repo);
    final notifier = container.read(postsViewModelProvider.notifier);

    unawaited(notifier.load()); // -> loading, hangs
    unawaited(notifier.load()); // guarded: must NOT issue a second request
    await Future<void>.value(); // flush microtasks

    expect(repo.calls, 1);
    expect(container.read(postsViewModelProvider).isLoading, isTrue);
  });
}
