// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectEntityImpl _$$ProjectEntityImplFromJson(Map<String, dynamic> json) =>
    _$ProjectEntityImpl(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$$ProjectEntityImplToJson(_$ProjectEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'name': instance.name,
      'description': instance.description,
      'color': instance.color,
      'icon': instance.icon,
      'isDefault': instance.isDefault,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };

_$ProjectMemberEntityImpl _$$ProjectMemberEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectMemberEntityImpl(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String? ?? 'viewer',
      invitedBy: json['invitedBy'] as String?,
      invitedAt: DateTime.parse(json['invitedAt'] as String),
      acceptedAt: json['acceptedAt'] == null
          ? null
          : DateTime.parse(json['acceptedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ProjectMemberEntityImplToJson(
        _$ProjectMemberEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'userId': instance.userId,
      'role': instance.role,
      'invitedBy': instance.invitedBy,
      'invitedAt': instance.invitedAt.toIso8601String(),
      'acceptedAt': instance.acceptedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
