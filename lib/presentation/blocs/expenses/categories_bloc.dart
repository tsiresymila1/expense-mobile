import 'package:expense/data/local/database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';

abstract class CategoriesEvent {}

class LoadCategories extends CategoriesEvent {}

class AddCategory extends CategoriesEvent {
  final String name;
  final String? icon;
  final String? color;

  AddCategory({required this.name, this.icon, this.color});
}

class DeleteCategory extends CategoriesEvent {
  final String id;
  DeleteCategory(this.id);
}

class UpdateCategory extends CategoriesEvent {
  final String id;
  final String name;
  final String? icon;
  final String? color;

  UpdateCategory({required this.id, required this.name, this.icon, this.color});
}

class CategoriesState {
  final List<LocalCategory> categories;
  final bool isLoading;

  CategoriesState({this.categories = const [], this.isLoading = false});

  CategoriesState copyWith({List<LocalCategory>? categories, bool? isLoading}) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final AppDatabase _db;

  CategoriesBloc(this._db) : super(CategoriesState()) {
    on<LoadCategories>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      
      // Check if categories are empty for THIS user and we haven't seeded yet
      final userCategories = await (_db.select(_db.localCategories)..where((t) => t.userId.equals(userId))).get();
      final hasSyncItems = (await (_db.select(_db.syncQueue)..where((t) => t.targetTable.equals('categories'))).get()).isNotEmpty;
      
      if (userCategories.isEmpty && !hasSyncItems) {
        await _seedDefaultCategories();
      }

      // Use watch to get real-time updates from the database for this user
      final query = _db.select(_db.localCategories)
        ..where((t) => t.userId.equals(userId) | t.isDefault.equals(true));
        
      await emit.forEach(
        query.watch(),
        onData: (categories) => state.copyWith(
          categories: categories,
          isLoading: false,
        ),
      );
    }, transformer: restartable());

    on<AddCategory>((event, emit) async {
      try {
        final id = const Uuid().v4();
        final userId = Supabase.instance.client.auth.currentUser?.id;

        await _db.into(_db.localCategories).insert(LocalCategoriesCompanion.insert(
          id: id,
          name: event.name,
          userId: drift.Value(userId),
          icon: drift.Value(event.icon),
          color: drift.Value(event.color),
          updatedAt: DateTime.now(),
        ));

        await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
          userId: userId ?? '',
          targetTable: 'categories',
          rowId: id,
          operation: 'INSERT',
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Error adding category: $e');
      }
    });

    on<UpdateCategory>((event, emit) async {
      try {
        await (_db.update(_db.localCategories)..where((t) => t.id.equals(event.id))).write(
          LocalCategoriesCompanion(
            name: drift.Value(event.name),
            icon: drift.Value(event.icon),
            color: drift.Value(event.color),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );

        final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
        await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
          userId: userId,
          targetTable: 'categories',
          rowId: event.id,
          operation: 'UPDATE',
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Error updating category: $e');
      }
    });

    on<DeleteCategory>((event, emit) async {
      try {
        await (_db.delete(_db.localCategories)..where((t) => t.id.equals(event.id))).go();

        final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
        await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
          userId: userId,
          targetTable: 'categories',
          rowId: event.id,
          operation: 'DELETE',
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Error deleting category: $e');
      }
    });
  }

  Future<void> _seedDefaultCategories() async {
    final defaults = [
      {'name': 'Food', 'icon': 'Food', 'color': Colors.orange.toARGB32().toRadixString(16)},
      {'name': 'Transport', 'icon': 'Transport', 'color': Colors.blue.toARGB32().toRadixString(16)},
      {'name': 'Shopping', 'icon': 'Shopping', 'color': Colors.pink.toARGB32().toRadixString(16)},
      {'name': 'Health', 'icon': 'Health', 'color': Colors.red.toARGB32().toRadixString(16)},
      {'name': 'Entertainment', 'icon': 'Entertainment', 'color': Colors.purple.toARGB32().toRadixString(16)},
    ];

    final userId = Supabase.instance.client.auth.currentUser?.id;

    for (var def in defaults) {
      final id = const Uuid().v4();
      await _db.into(_db.localCategories).insert(LocalCategoriesCompanion.insert(
        id: id,
        name: def['name']!,
        userId: drift.Value(userId),
        icon: drift.Value(def['icon']),
        color: drift.Value(def['color']),
        isDefault: const drift.Value(true),
        updatedAt: DateTime.now(),
      ));

      // Add to sync queue so default categories are available on other devices
      await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
        userId: userId ?? '',
        targetTable: 'categories',
        rowId: id,
        operation: 'INSERT',
        createdAt: DateTime.now(),
      ));
    }
  }
}
