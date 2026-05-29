import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';

/// Domain entity for a post. Immutable, equatable, and free of any wire/JSON
/// concerns (that is the DTO's job). The presentation layer only ever sees
/// this.
@freezed
abstract class Post with _$Post {
  const factory Post({
    required int id,
    required String title,
    required String body,
  }) = _Post;
}
