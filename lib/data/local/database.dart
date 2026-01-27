import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class LocalProjects extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalProjectMembers extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text().withDefault(const Constant('viewer'))();
  TextColumn get invitedBy => text().nullable()();
  DateTimeColumn get invitedAt => dateTime()();
  DateTimeColumn get acceptedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get type =>
      text().withDefault(const Constant('expense'))(); // 'expense' or 'income'
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get targetTable => text()();
  TextColumn get rowId => text()();
  TextColumn get operation => text()(); // 'INSERT', 'UPDATE', 'DELETE'
  TextColumn get payload => text().nullable()(); // JSON string
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [LocalProjects, LocalProjectMembers, LocalExpenses, LocalCategories, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await _addColumnSafely(m, localExpenses, 'type');
        }
        if (from < 3) {
          await _addColumnSafely(m, localCategories, 'user_id');
          await _addColumnSafely(m, syncQueue, 'user_id');
        }
        if (from < 4) {
          await _addColumnSafely(m, localExpenses, 'deleted_at');
          await _addColumnSafely(m, localCategories, 'deleted_at');
        }
        if (from < 5) {
          // Add projects support
          await m.createTable(localProjects);
          await m.createTable(localProjectMembers);
          await _addColumnSafely(m, localExpenses, 'project_id');
        }
      },
    );
  }

  Future<void> _addColumnSafely(
    Migrator m,
    TableInfo table,
    String columnName,
  ) async {
    try {
      // Check if column exists
      final result = await customSelect(
        'PRAGMA table_info("${table.actualTableName}")',
      ).get();
      final hasColumn = result.any((row) => row.data['name'] == columnName);

      if (!hasColumn) {
        // Find the column by its entity name (camelCase in Dart, usually matches the getter name)
        final column =
            table.columnsByName[columnName] ??
            table.columnsByName.values.firstWhere((c) => c.name == columnName);
        await m.addColumn(table, column);
      }
    } catch (e) {
      debugPrint(
        'Error adding column $columnName to ${table.actualTableName}: $e',
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'expense_db.sqlite'));
    return NativeDatabase(file);
  });
}
