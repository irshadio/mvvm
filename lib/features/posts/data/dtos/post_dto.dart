import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';

part 'post_dto.freezed.dart';
part 'post_dto.g.dart';

/// Wire model for a post (JSONPlaceholder shape). JSON lives here, never in the
/// domain entity.
@freezed
abstract class PostDto with _$PostDto {
  const factory PostDto({
    required int id,
    required int userId,
    required String title,
    required String body,
  }) = _PostDto;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
}

/// DTO -> domain mapping. Kept in the data layer (data may depend on domain).
extension PostDtoMapper on PostDto {
  Post toEntity() => Post(id: id, title: title, body: body);
}
