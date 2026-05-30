import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/features/posts/domain/entities/create_post_input.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';
import 'package:mvvm/features/posts/presentation/view/create_post_view.dart';

/// Repository whose createPost result is configurable (success or failure).
class _StubRepository implements PostRepository {
  _StubRepository(this.created);

  final Either<Failure, Post> created;

  @override
  Future<Either<Failure, Post>> createPost(CreatePostInput input) async =>
      created.map(
        (post) => Post(id: post.id, title: input.title, body: input.body),
      );

  @override
  Future<Either<Failure, List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, Post>> getPost(int id) async =>
      throw UnimplementedError();
}

Future<void> _pumpForm(WidgetTester tester, PostRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [postRepositoryProvider.overrideWith((ref) => repo)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<Post>(
                    builder: (_) => const CreatePostView(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('valid submit creates the post, snackbars, and pops', (
    tester,
  ) async {
    await _pumpForm(
      tester,
      _StubRepository(
        right<Failure, Post>(const Post(id: 101, title: '', body: '')),
      ),
    );
    expect(find.text('New post'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Hello');
    await tester.enterText(fields.at(1), 'A body');
    await tester.tap(find.text('Create post'));
    await tester.pumpAndSettle();

    // Popped back to the launcher; the form is gone and success is surfaced.
    expect(find.text('New post'), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(find.textContaining('created'), findsOneWidget);
  });

  testWidgets('empty fields fail validation and do not submit', (tester) async {
    await _pumpForm(
      tester,
      _StubRepository(
        right<Failure, Post>(const Post(id: 101, title: '', body: '')),
      ),
    );

    await tester.tap(find.text('Create post'));
    await tester.pumpAndSettle();

    // Still on the form, with validation errors and no navigation.
    expect(find.text('New post'), findsOneWidget);
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Body is required'), findsOneWidget);
  });
}
