import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_post_input.freezed.dart';

/// Input for creating a post — a domain value object, free of any wire/JSON
/// concerns (the data layer maps it to the request body).
///
/// `userId` would normally come from the authenticated session; the auth
/// feature is stubbed, so it defaults to `1` for the demo.
@freezed
abstract class CreatePostInput with _$CreatePostInput {
  const factory CreatePostInput({
    required String title,
    required String body,
    @Default(1) int userId,
  }) = _CreatePostInput;
}
