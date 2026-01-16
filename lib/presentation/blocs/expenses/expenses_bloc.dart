import 'package:expense/data/local/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'expenses_event.dart';
import 'expenses_state.dart';

export 'expenses_event.dart';
export 'expenses_state.dart';

class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  final AppDatabase database;

  ExpensesBloc(this.database) : super(ExpensesState(expenses: [])) {
    on<LoadExpenses>(_onLoad);
    on<AddExpense>(_onAdd);
    on<UpdateExpense>(_onUpdate);
    on<DeleteExpense>(_onDelete);
  }

  Future<void> _onLoad(LoadExpenses event, Emitter<ExpensesState> emit) async {
    emit(
      state.copyWith(
        isLoading: true,
        dateRange: event.dateRange,
        amountRange: event.amountRange,
      ),
    );
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
      1,
    );
    final lastMonthEnd = thisMonthStart.subtract(const Duration(seconds: 1));

    var query = database.select(database.localExpenses)
      ..where((t) => t.userId.equals(userId));
    if (event.dateRange != null)
      query.where(
        (t) => t.date.isBetweenValues(
          event.dateRange!.start,
          event.dateRange!.end,
        ),
      );
    if (event.amountRange != null)
      query.where(
        (t) => t.amount.isBetweenValues(
          event.amountRange!.start,
          event.amountRange!.end,
        ),
      );
    final expenses = await (query..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    double thisIn = 0, thisEx = 0, lastTot = 0, filtIn = 0, filtEx = 0;
    final dailyMap = <int, double>{};
    final all = await (database.select(
      database.localExpenses,
    )..where((t) => t.userId.equals(userId))).get();

    for (var e in all) {
      final isIn = e.type == 'income';
      if (e.date.isAfter(thisMonthStart) ||
          e.date.isAtSameMomentAs(thisMonthStart)) {
        if (isIn)
          thisIn += e.amount;
        else {
          thisEx += e.amount;
          if (e.date.month == now.month && e.date.year == now.year)
            dailyMap[e.date.day] = (dailyMap[e.date.day] ?? 0) + e.amount;
        }
      } else if (e.date.isAfter(lastMonthStart) &&
          e.date.isBefore(lastMonthEnd)) {
        lastTot += isIn ? e.amount : -e.amount;
      }
    }
    for (var e in expenses) {
      if (e.type == 'income')
        filtIn += e.amount;
      else
        filtEx += e.amount;
    }

    emit(
      state.copyWith(
        expenses: expenses,
        thisMonthTotal: thisIn - thisEx,
        thisMonthIncome: thisIn,
        thisMonthExpense: thisEx,
        lastMonthTotal: lastTot,
        filteredIncome: filtIn,
        filteredExpense: filtEx,
        dailySpending: List.generate(31, (i) => dailyMap[i + 1] ?? 0),
        isLoading: false,
        dateRange: event.dateRange,
        amountRange: event.amountRange,
      ),
    );
  }

  Future<void> _onAdd(AddExpense event, Emitter<ExpensesState> emit) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      final id = const Uuid().v4();
      await database
          .into(database.localExpenses)
          .insert(
            LocalExpensesCompanion.insert(
              id: id,
              userId: userId,
              categoryId: Value(event.categoryId),
              amount: event.amount,
              type: Value(event.type),
              date: event.date,
              note: Value(event.note),
              updatedAt: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          );
      await database
          .into(database.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              userId: userId,
              targetTable: 'expenses',
              rowId: id,
              operation: 'INSERT',
              createdAt: DateTime.now(),
            ),
          );
    } catch (e) {
      debugPrint('Error adding expense: $e');
    }
    add(
      LoadExpenses(dateRange: state.dateRange, amountRange: state.amountRange),
    );
  }

  Future<void> _onUpdate(
    UpdateExpense event,
    Emitter<ExpensesState> emit,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      await (database.update(
        database.localExpenses,
      )..where((t) => t.id.equals(event.id))).write(
        LocalExpensesCompanion(
          amount: Value(event.amount),
          type: Value(event.type),
          categoryId: Value(event.categoryId),
          date: Value(event.date),
          note: Value(event.note),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await database
          .into(database.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              userId: userId,
              targetTable: 'expenses',
              rowId: event.id,
              operation: 'UPDATE',
              createdAt: DateTime.now(),
            ),
          );
    } catch (e) {
      debugPrint('Error updating expense: $e');
    }
    add(
      LoadExpenses(dateRange: state.dateRange, amountRange: state.amountRange),
    );
  }

  Future<void> _onDelete(
    DeleteExpense event,
    Emitter<ExpensesState> emit,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      await (database.delete(
        database.localExpenses,
      )..where((t) => t.id.equals(event.id))).go();
      await database
          .into(database.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              userId: userId,
              targetTable: 'expenses',
              rowId: event.id,
              operation: 'DELETE',
              createdAt: DateTime.now(),
            ),
          );
    } catch (e) {
      debugPrint('Error deleting expense: $e');
    }
    add(
      LoadExpenses(dateRange: state.dateRange, amountRange: state.amountRange),
    );
  }
}
