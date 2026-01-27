import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_entity.freezed.dart';
part 'project_entity.g.dart';

@freezed
class ProjectEntity with _$ProjectEntity {
  const factory ProjectEntity({
    required String id,
    required String ownerId,
    required String name,
    String? description,
    String? color,
    String? icon,
    @Default(false) bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _ProjectEntity;

  factory ProjectEntity.fromJson(Map<String, dynamic> json) =>
      _$ProjectEntityFromJson(json);
}

@freezed
class ProjectMemberEntity with _$ProjectMemberEntity {
  const factory ProjectMemberEntity({
    required String id,
    required String projectId,
    required String userId,
    @Default('viewer') String role,
    String? invitedBy,
    required DateTime invitedAt,
    DateTime? acceptedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProjectMemberEntity;

  factory ProjectMemberEntity.fromJson(Map<String, dynamic> json) =>
      _$ProjectMemberEntityFromJson(json);
}
