import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/app/app.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/network/connectivity.dart';
import 'package:mvvm/features/posts/domain/entities/create_post_input.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';

/// Fake repository so the boot path needs no network or database.
class _FakePostRepository implements PostRepository {
  @override
  Future<Either<Failure, List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
  }) async => right<Failure, List<Post>>(
    const <Post>[Post(id: 1, title: 'Hello', body: 'World')],
  );

  @override
  Future<Either<Failure, Post>> getPost(int id) async =>
      right<Failure, Post>(const Post(id: 1, title: 'Hello', body: 'World'));

  @override
  Future<Either<Failure, Post>> createPost(CreatePostInput input) async =>
      right<Failure, Post>(
        Post(id: 101, title: input.title, body: input.body),
      );
}

void main() {
  // Boots the whole app (composition root -> splash -> routing -> posts) with
  // only the repository faked. Guards the runtime wiring that compile-time
  // checks cannot: a forgotten ProviderScope override throws UnimplementedError
  // here rather than in production.
  testWidgets('boots through splash to posts without UnimplementedError', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWith((ref) => _FakePostRepository()),
          // Finite stream: no DNS probes, no pending periodic timer in tests.
          connectivityStatusProvider.overrideWith(
            (ref) => Stream<bool>.value(true),
          ),
        ],
        child: const App(),
      ),
    );

    // Splash is shown first.
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    // Let the splash delay elapse, navigation occur, and posts load.
    await tester.pumpAndSettle();

    // Navigated to the posts list and rendered the faked data.
    expect(find.text('Hello'), findsOneWidget);
  });
}
