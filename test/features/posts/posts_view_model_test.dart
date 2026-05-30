import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';
import 'package:mvvm/features/posts/presentation/view_model/posts_view_model.dart';

/// Stub repository whose result can be swapped between calls (to model a
/// refresh that succeeds then fails).
class _StubRepository implements PostRepository {
  _StubRepository(this.result);

  Either<Failure, List<Post>> result;

  @override
  Future<Either<Failure, List<Post>>> getPosts() async => result;

  @override
  Future<Either<Failure, Post>> getPost(int id) async =>
      throw UnimplementedError();
}

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
}
