import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_entity.freezed.dart';
part 'expense_entity.g.dart';

@freezed
class ExpenseEntity with _$ExpenseEntity {
  const factory ExpenseEntity({
    required String id,
    required String userId,
    String? categoryId,
    required double amount,
    required DateTime date,
    String? note,
    required DateTime updatedAt,
    required DateTime createdAt,
  }) = _ExpenseEntity;

  factory ExpenseEntity.fromJson(Map<String, dynamic> json) =>
      _$ExpenseEntityFromJson(json);
}

@freezed
class CategoryEntity with _$CategoryEntity {
  const factory CategoryEntity({
    required String id,
    String? userId,
    required String name,
    String? icon,
    String? color,
    @Default(false) bool isDefault,
    required DateTime updatedAt,
  }) = _CategoryEntity;

  factory CategoryEntity.fromJson(Map<String, dynamic> json) =>
      _$CategoryEntityFromJson(json);
}
