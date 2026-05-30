import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/state/submission_state.dart';
import 'package:mvvm/features/posts/domain/entities/create_post_input.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';
import 'package:mvvm/features/posts/presentation/view_model/create_post_view_model.dart';

/// Stub repository whose createPost result is swappable.
class _StubRepository implements PostRepository {
  _StubRepository(this.created);

  Either<Failure, Post> created;

  @override
  Future<Either<Failure, Post>> createPost(CreatePostInput input) async =>
      created;

  @override
  Future<Either<Failure, List<Post>>> getPosts() async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Post>> getPost(int id) async =>
      throw UnimplementedError();
}

void main() {
  const input = CreatePostInput(title: 'New', body: 'Body');
  const created = Post(id: 101, title: 'New', body: 'Body');

  ProviderContainer containerWith(_StubRepository repo) {
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWith((ref) => repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('build() starts idle', () {
    final container = containerWith(
      _StubRepository(right<Failure, Post>(created)),
    );
    expect(
      container.read(createPostViewModelProvider),
      const SubmissionState<Post>.idle(),
    );
  });

  test('submit() success maps to SubmissionState.success', () async {
    final container = containerWith(
      _StubRepository(right<Failure, Post>(created)),
    );
    await container.read(createPostViewModelProvider.notifier).submit(input);
    expect(
      container.read(createPostViewModelProvider),
      const SubmissionState<Post>.success(created),
    );
  });

  test('submit() failure maps to SubmissionState.failure', () async {
    const failure = Failure.server(statusCode: 422, message: 'invalid');
    final container = containerWith(
      _StubRepository(left<Failure, Post>(failure)),
    );
    await container.read(createPostViewModelProvider.notifier).submit(input);
    expect(
      container.read(createPostViewModelProvider),
      const SubmissionState<Post>.failure(failure),
    );
  });
}
