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

  Future<void> addCategory({
    required String name,
    String? icon,
    required String color,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final id = db.id();
    try {
      final ops = <Operation>[
        ...db.tx['categories'].create({
          'id': id,
          'ownerId': uid,
          'name': name,
          'icon': icon,
          'color': color,
          'isDefault': false,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }).operations,
        ...db.tx['categories'][id].link({'owner': uid}).operations,
      ];
      await db.transact(ops);
    } catch (e) {
      debugPrint('Error adding category: $e');
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
