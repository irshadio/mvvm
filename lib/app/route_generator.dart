import 'package:flutter/material.dart';
import 'package:mvvm/core/routing/app_routes.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/presentation/view/create_post_view.dart';
import 'package:mvvm/features/posts/presentation/view/post_detail_view.dart';
import 'package:mvvm/features/posts/presentation/view/posts_view.dart';
import 'package:mvvm/features/splash/presentation/view/splash_view.dart';

/// Central `onGenerateRoute` for Navigator 1.0: maps route names to pages and
/// unpacks typed arguments.
///
/// Lives in `app/` (NOT `core/`) because it must import feature views, and core
/// may never depend on features. Each feature registers its routes here.
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.splash:
      return _materialRoute<void>(const SplashView(), settings);
    case Routes.home:
      return _materialRoute<void>(const PostsView(), settings);
    case Routes.postDetail:
      final argument = settings.arguments;
      if (argument is! Post) {
        return _errorRoute('postDetail requires a Post argument', settings);
      }
      return _materialRoute<void>(PostDetailView(post: argument), settings);
    case Routes.createPost:
      // Typed to its return value: callers push `pushNamed<Post>` and the form
      // pops a `Post`. A `MaterialPageRoute<void>` here makes Navigator's
      // internal `as Route<Post?>?` cast throw, so the route MUST carry `Post`.
      return _materialRoute<Post>(const CreatePostView(), settings);
    default:
      return _errorRoute('No route defined for "${settings.name}"', settings);
  }
}

/// Builds a typed [MaterialPageRoute]. [T] is the route's *result* type — it
/// must match the type argument callers use with `pushNamed<T>` / `pop<T>`,
/// because `Navigator` casts the generated route to `Route<T?>?` on push.
Route<dynamic> _materialRoute<T>(Widget page, RouteSettings settings) =>
    MaterialPageRoute<T>(builder: (_) => page, settings: settings);

Route<dynamic> _errorRoute(String message, RouteSettings settings) =>
    MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Navigation error')),
        body: Center(child: Text(message)),
      ),
    );
