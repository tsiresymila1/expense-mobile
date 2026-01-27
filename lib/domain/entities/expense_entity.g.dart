// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExpenseEntityImpl _$$ExpenseEntityImplFromJson(Map<String, dynamic> json) =>
    _$ExpenseEntityImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      projectId: json['projectId'] as String?,
      categoryId: json['categoryId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ExpenseEntityImplToJson(_$ExpenseEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'projectId': instance.projectId,
      'categoryId': instance.categoryId,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'note': instance.note,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$CategoryEntityImpl _$$CategoryEntityImplFromJson(Map<String, dynamic> json) =>
    _$CategoryEntityImpl(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$CategoryEntityImplToJson(
        _$CategoryEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'isDefault': instance.isDefault,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
