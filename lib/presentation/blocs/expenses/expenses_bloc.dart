import 'package:expense/data/local/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ExpensesEvent {}

class LoadExpenses extends ExpensesEvent {
  final DateTimeRange? dateRange;
  final RangeValues? amountRange;
  LoadExpenses({this.dateRange, this.amountRange});
}

class AddExpense extends ExpensesEvent {
  final double amount;
  final String? categoryId;
  final DateTime date;
  final String? note;
  final String type; // 'expense' or 'income'
  AddExpense({required this.amount, this.categoryId, required this.date, this.note, this.type = 'expense'});
}

class UpdateExpense extends ExpensesEvent {
  final String id;
  final double amount;
  final String? categoryId;
  final DateTime date;
  final String? note;
  final String type; // 'expense' or 'income'
  UpdateExpense({required this.id, required this.amount, this.categoryId, required this.date, this.note, this.type = 'expense'});
}

class DeleteExpense extends ExpensesEvent {
  final String id;
  DeleteExpense(this.id);
}

class ExpensesState {
  final List<LocalExpense> expenses;
  final double thisMonthTotal; // Balance: Income - Expense
  final double thisMonthIncome;
  final double thisMonthExpense;
  final double lastMonthTotal;
  final double filteredIncome;
  final double filteredExpense;
  final List<double> dailySpending; // Expenses only for chart
  final bool isLoading;
  final DateTimeRange? dateRange;
  final RangeValues? amountRange;

  ExpensesState({
    required this.expenses,
    this.thisMonthTotal = 0,
    this.thisMonthIncome = 0,
    this.thisMonthExpense = 0,
    this.lastMonthTotal = 0,
    this.filteredIncome = 0,
    this.filteredExpense = 0,
    this.dailySpending = const [],
    this.isLoading = false,
    this.dateRange,
    this.amountRange,
  });

  ExpensesState copyWith({
    List<LocalExpense>? expenses,
    double? thisMonthTotal,
    double? thisMonthIncome,
    double? thisMonthExpense,
    double? lastMonthTotal,
    double? filteredIncome,
    double? filteredExpense,
    List<double>? dailySpending,
    bool? isLoading,
    DateTimeRange? dateRange,
    RangeValues? amountRange,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      thisMonthTotal: thisMonthTotal ?? this.thisMonthTotal,
      thisMonthIncome: thisMonthIncome ?? this.thisMonthIncome,
      thisMonthExpense: thisMonthExpense ?? this.thisMonthExpense,
      lastMonthTotal: lastMonthTotal ?? this.lastMonthTotal,
      filteredIncome: filteredIncome ?? this.filteredIncome,
      filteredExpense: filteredExpense ?? this.filteredExpense,
      dailySpending: dailySpending ?? this.dailySpending,
      isLoading: isLoading ?? this.isLoading,
      dateRange: dateRange,
      amountRange: amountRange,
    );
  }
}

class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  final AppDatabase database;

  ExpensesBloc(this.database) : super(ExpensesState(expenses: [])) {
    on<LoadExpenses>((event, emit) async {
      emit(state.copyWith(isLoading: true, dateRange: event.dateRange, amountRange: event.amountRange));
      
      final now = DateTime.now();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final lastMonthStart = DateTime(prevYear, prevMonth, 1);
      final lastMonthEnd = thisMonthStart.subtract(const Duration(seconds: 1));

      var query = database.select(database.localExpenses);
      query.where((t) => t.userId.equals(userId));

      if (event.dateRange != null) {
        query.where((t) => t.date.isBetweenValues(event.dateRange!.start, event.dateRange!.end));
      }
      
      if (event.amountRange != null) {
        query.where((t) => t.amount.isBetweenValues(event.amountRange!.start, event.amountRange!.end));
      }

      final expenses = await (query..orderBy([(t) => OrderingTerm.desc(t.date)])).get();

      double thisMonthIncome = 0;
      double thisMonthExpense = 0;
      double lastMonthTotal = 0;
      final dailySpendingMap = <int, double>{};
      
      final allExpenses = await (database.select(database.localExpenses)..where((t) => t.userId.equals(userId))).get();
      for (var expense in allExpenses) {
        final isIncome = expense.type == 'income';
        
        if (expense.date.isAfter(thisMonthStart) || expense.date.isAtSameMomentAs(thisMonthStart)) {
          if (isIncome) {
            thisMonthIncome += expense.amount;
          } else {
            thisMonthExpense += expense.amount;
            if (expense.date.month == now.month && expense.date.year == now.year) {
               dailySpendingMap[expense.date.day] = (dailySpendingMap[expense.date.day] ?? 0) + expense.amount;
            }
          }
        } else if (expense.date.isAfter(lastMonthStart) && expense.date.isBefore(lastMonthEnd)) {
          if (isIncome) {
            lastMonthTotal += expense.amount;
          } else {
            lastMonthTotal -= expense.amount;
          }
        }
      }

      final dailySpending = List<double>.generate(31, (index) => dailySpendingMap[index + 1] ?? 0.0);

      double filteredIncome = 0;
      double filteredExpense = 0;
      for (var expense in expenses) {
        if (expense.type == 'income') {
          filteredIncome += expense.amount;
        } else {
          filteredExpense += expense.amount;
        }
      }

      emit(state.copyWith(
        expenses: expenses,
        thisMonthTotal: thisMonthIncome - thisMonthExpense,
        thisMonthIncome: thisMonthIncome,
        thisMonthExpense: thisMonthExpense,
        lastMonthTotal: lastMonthTotal,
        filteredIncome: filteredIncome,
        filteredExpense: filteredExpense,
        dailySpending: dailySpending,
        isLoading: false,
        dateRange: event.dateRange,
        amountRange: event.amountRange,
      ));
    });

    on<AddExpense>((event, emit) async {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      try {
        final id = const Uuid().v4();
        
        final expense = LocalExpensesCompanion.insert(
          id: id,
          userId: userId,
          categoryId: Value(event.categoryId),
          amount: event.amount,
          type: Value(event.type),
          date: event.date,
          note: Value(event.note),
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await database.into(database.localExpenses).insert(expense);
        
        await database.into(database.syncQueue).insert(SyncQueueCompanion.insert(
          userId: userId,
          targetTable: 'expenses',
          rowId: id,
          operation: 'INSERT',
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Error adding expense: $e');
      }

      add(LoadExpenses(dateRange: state.dateRange, amountRange: state.amountRange));
    });

    on<UpdateExpense>((event, emit) async {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      try {
        await (database.update(database.localExpenses)..where((t) => t.id.equals(event.id))).write(
          LocalExpensesCompanion(
            amount: Value(event.amount),
            type: Value(event.type),
            categoryId: Value(event.categoryId),
            date: Value(event.date),
            note: Value(event.note),
            updatedAt: Value(DateTime.now()),
          ),
        );

        await database.into(database.syncQueue).insert(SyncQueueCompanion.insert(
          userId: userId,
          targetTable: 'expenses',
          rowId: event.id,
          operation: 'UPDATE',
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Error updating expense: $e');
      }

      add(LoadExpenses(dateRange: state.dateRange, amountRange: state.amountRange));
    });

    on<DeleteExpense>((event, emit) async {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      try {
        await (database.delete(database.localExpenses)..where((t) => t.id.equals(event.id))).go();

        await database.into(database.syncQueue).insert(SyncQueueCompanion.insert(
          userId: userId,
          targetTable: 'expenses',
          rowId: event.id,
          operation: 'DELETE',
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Error deleting expense: $e');
      }

      add(LoadExpenses(dateRange: state.dateRange, amountRange: state.amountRange));
    });
  }
}
