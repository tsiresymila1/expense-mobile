import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:expense/data/models/models.dart';
import 'categories_state.dart';

export 'categories_state.dart';

/// Categories over InstantDB. Shows the user's own categories plus global
/// defaults (ownerId == null).
class CategoriesCubit extends Cubit<CategoriesState> {
  final InstantDB db;
  void Function()? _queryDispose;
  late final StreamSubscription<AuthUser?> _authSub;

  CategoriesCubit(this.db) : super(CategoriesState(categories: [])) {
    _subscribe();
    _authSub = db.auth.onAuthStateChange.listen((_) => _subscribe());
  }

  String? get _uid => db.auth.currentUser.value?.id;

  /// Kept for call-site compatibility; the subscription keeps data live.
  void loadCategories() {}

  void _subscribe() {
    _queryDispose?.call();
    final uid = _uid;
    emit(state.copyWith(isLoading: true));
    final sig = db.subscribeQuery({'categories': {}});
    _queryDispose = effect(() {
      final res = sig.value;
      final all = mapList(res.data?['categories'], Category.fromMap);
      // Own categories + global defaults.
      final visible = all
          .where((c) => c.isDefault || c.ownerId == null || c.ownerId == uid)
          .toList();
      emit(state.copyWith(categories: visible, isLoading: false));
    });
  }

  /// Creates a category and returns its id (null when it could not be saved).
  Future<String?> addCategory({
    required String name,
    String? icon,
    required String color,
  }) => _create(name: name, icon: icon, color: color);

  /// Re-creates a deleted category under its original id so transactions that
  /// still reference it (scalar `categoryId`) point to it again.
  Future<void> restoreCategory(Category c) => _create(
    id: c.id,
    name: c.name,
    icon: c.icon,
    color: c.color ?? '',
    isDefault: c.isDefault,
  );

  Future<String?> _create({
    String? id,
    required String name,
    String? icon,
    required String color,
    bool isDefault = false,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    final newId = id ?? db.id();
    try {
      final ops = <Operation>[
        ...db.tx['categories'].create({
          'id': newId,
          'ownerId': uid,
          'name': name,
          'icon': icon,
          'color': color,
          'isDefault': isDefault,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }).operations,
        ...db.tx['categories'][newId].link({'owner': uid}).operations,
      ];
      await db.transact(ops);
      return newId;
    } catch (e) {
      debugPrint('Error adding category: $e');
      return null;
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    String? icon,
    required String color,
  }) async {
    try {
      await db.transact(
        db.tx['categories'][id].update({
          'name': name,
          'icon': icon,
          'color': color,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
      debugPrint('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await db.transact(db.tx['categories'][id].delete());
    } catch (e) {
      debugPrint('Error deleting category: $e');
    }
  }

  @override
  Future<void> close() {
    _queryDispose?.call();
    _authSub.cancel();
    return super.close();
  }
}
