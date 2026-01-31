import 'package:expense/data/local/database.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';
import 'package:expense/core/sync_engine/engine.dart';
import 'categories_event.dart';
import 'categories_state.dart';

export 'categories_event.dart';
export 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final AppDatabase database;
  final SyncEngine syncEngine;
  CategoriesBloc(this.database, this.syncEngine) : super(CategoriesState(categories: [])) {
    on<LoadCategories>(_onLoad);
    on<AddCategory>(_onAdd);
    on<UpdateCategory>(_onUpdate);
    on<DeleteCategory>(_onDelete);

    _syncSubscription = syncEngine.syncState.listen((state) {
      if (state.status == SyncStatus.success) {
        add(LoadCategories());
      }
    });
  }

  late final StreamSubscription<SyncState> _syncSubscription;

  @override
  Future<void> close() {
    _syncSubscription.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final categories = await (database.select(
      database.localCategories,
    )..where((t) =>
            (t.userId.equals(userId) | t.isDefault.equals(true)) &
            t.deletedAt.isNull())).get();
    emit(state.copyWith(categories: categories, isLoading: false));
  }

  Future<void> _onAdd(AddCategory event, Emitter<CategoriesState> emit) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      final id = const Uuid().v4();
      await database
          .into(database.localCategories)
          .insert(
            LocalCategoriesCompanion.insert(
              id: id,
              userId: Value(userId),
              name: event.name,
              icon: Value(event.icon),
              color: Value(event.color),
              updatedAt: DateTime.now(),
            ),
          );
      await syncEngine.localDb.addToSyncQueue(
        userId,
        'categories',
        id,
        'INSERT',
      );
      syncEngine.triggerSync();
    } catch (e) {
      debugPrint('Error adding category: $e');
    }
    add(LoadCategories());
  }

  Future<void> _onUpdate(
    UpdateCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      await (database.update(
        database.localCategories,
      )..where((t) => t.id.equals(event.id))).write(
        LocalCategoriesCompanion(
          name: Value(event.name),
          icon: Value(event.icon),
          color: Value(event.color),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await syncEngine.localDb.addToSyncQueue(
        userId,
        'categories',
        event.id,
        'UPDATE',
      );
      syncEngine.triggerSync();
    } catch (e) {
      debugPrint('Error updating category: $e');
    }
    add(LoadCategories());
  }

  Future<void> _onDelete(
    DeleteCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      // Soft delete: mark as deleted instead of removing from database
      await (database.update(
        database.localCategories,
      )..where((t) => t.id.equals(event.id))).write(
        LocalCategoriesCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await syncEngine.localDb.addToSyncQueue(
        userId,
        'categories',
        event.id,
        'UPDATE', // Soft Delete
      );
      syncEngine.triggerSync();
    } catch (e) {
      debugPrint('Error deleting category: $e');
    }
    add(LoadCategories());
  }
}
