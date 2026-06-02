import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/app/route_generator.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/routing/app_routes.dart';
import 'package:mvvm/features/posts/domain/entities/create_post_input.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';
import 'package:mvvm/features/posts/presentation/view/create_post_view.dart';

/// Guards `onGenerateRoute` directly. The create-post crash shipped because no
/// test went through the REAL generator: `create_post_view_test` builds its own
/// `MaterialPageRoute<Post>` and bypasses it. These assert the route *contract*
/// callers rely on — in particular that a value-returning route is typed to its
/// result, so Navigator's internal `as Route<T?>?` cast on `pushNamed<T>` does
/// not throw.
class _FakePostRepository implements PostRepository {
  @override
  Future<Either<Failure, Post>> createPost(CreatePostInput input) async =>
      right<Failure, Post>(Post(id: 101, title: input.title, body: input.body));

  @override
  Future<Either<Failure, Post>> getPost(int id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
  }) => throw UnimplementedError();
}

void main() {
  Route<dynamic> generate(String name, {Object? arguments}) =>
      onGenerateRoute(RouteSettings(name: name, arguments: arguments));

  test('createPost is typed Route<Post> (so pushNamed<Post> cannot crash)', () {
    // The regression assertion: a MaterialPageRoute<void> here would make
    // `Navigator.pushNamed<Post>` throw a CastError on push. Fails pre-fix.
    expect(generate(Routes.createPost), isA<MaterialPageRoute<Post>>());
  });

  test('splash / home / postDetail are void-typed routes', () {
    expect(generate(Routes.splash), isA<MaterialPageRoute<void>>());
    expect(generate(Routes.home), isA<MaterialPageRoute<void>>());
    expect(
      generate(
        Routes.postDetail,
        arguments: const Post(id: 1, title: 't', body: 'b'),
      ),
      isA<MaterialPageRoute<void>>(),
    );
  });

  testWidgets('pushNamed<Post>(createPost) reaches the form without a crash', (
    tester,
  ) async {
    Object? caught;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWith((ref) => _FakePostRepository()),
        ],
        child: MaterialApp(
          onGenerateRoute: onGenerateRoute,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  try {
                    await Navigator.of(
                      context,
                    ).pushNamed<Post>(Routes.createPost);
                  } on Object catch (e) {
                    caught = e;
                  }
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Pre-fix, the push threw a CastError here (swallowed by the app's
    // PlatformDispatcher.onError, leaving the FAB silently dead). Reaching the
    // form with no cast error is the regression guard.
    expect(caught, isNull);
    expect(find.byType(CreatePostView), findsOneWidget);
  });
}
