import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:expense/data/models/models.dart';
import 'expenses_state.dart';

export 'expenses_state.dart';

const _projectIdNotProvided = Object();

/// Expenses over InstantDB. Reads via a reactive [subscribeQuery] stream
/// (replaces the old Drift-write -> sync-queue -> reload-on-sync loop); writes
/// via [transact]. Aggregation (month totals, dailySpending) is computed
/// client-side from the streamed list, as before.
class ExpensesCubit extends Cubit<ExpensesState> {
  final InstantDB db;
  List<Expense> _allExpenses = [];
  void Function()? _queryDispose;
  late final StreamSubscription<AuthUser?> _authSub;

  ExpensesCubit(this.db) : super(ExpensesState(expenses: [])) {
    _subscribe();
    _authSub = db.auth.onAuthStateChange.listen((_) => _subscribe());
  }

  String? get _uid => db.auth.currentUser.value?.id;

  /// (Re)subscribe with the current filters. Called on construction, auth
  /// change, and whenever [loadExpenses] changes the active project.
  void _subscribe() {
    _queryDispose?.call();
    final uid = _uid;
    if (uid == null) {
      _allExpenses = [];
      emit(state.copyWith(expenses: [], allExpenses: [], isLoading: false));
      return;
    }
    emit(state.copyWith(isLoading: true));
    final projectId = state.currentProjectId;
    final where = projectId != null
        ? {'projectId': projectId}
        : {'creatorId': uid};
    final sig = db.subscribeQuery({
      'expenses': {'where': where},
    });
    _queryDispose = effect(() {
      final res = sig.value;
      // InstantDB may expose an unmodifiable collection; copy it before the
      // local project filter and newest-first sort.
      var list = List<Expense>.of(
        mapList(res.data?['expenses'], Expense.fromMap),
      );
      // Personal view: only expenses with no project.
      if (projectId == null) {
        list = list.where((e) => e.projectId == null).toList();
      }
      list.sort((a, b) => b.date.compareTo(a.date));
      _allExpenses = list;
      emit(_aggregate(list));
    });
  }

  void loadExpenses({
    Object? dateRange = _projectIdNotProvided,
    Object? amountRange = _projectIdNotProvided,
    Object? projectId = _projectIdNotProvided,
  }) {
    final newProject = identical(projectId, _projectIdNotProvided)
        ? state.currentProjectId
        : projectId as String?;
    final projectChanged = newProject != state.currentProjectId;
    emit(
      state.copyWith(
        dateRange: identical(dateRange, _projectIdNotProvided)
            ? state.dateRange
            : dateRange,
        amountRange: identical(amountRange, _projectIdNotProvided)
            ? state.amountRange
            : amountRange,
        currentProjectId: newProject,
      ),
    );
    if (projectChanged) {
      _subscribe();
    } else {
      // Re-aggregate with the new filters against the current list.
      emit(_aggregate(_allExpenses));
    }
  }

  ExpensesState _aggregate(List<Expense> all) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
      1,
    );
    final lastMonthEnd = thisMonthStart.subtract(const Duration(seconds: 1));

    // Filtered view (respects date/amount range).
    var filtered = all;
    if (state.dateRange != null) {
      filtered = filtered
          .where(
            (e) =>
                !e.date.isBefore(state.dateRange!.start) &&
                !e.date.isAfter(state.dateRange!.end),
          )
          .toList();
    }
    if (state.amountRange != null) {
      filtered = filtered
          .where(
            (e) =>
                e.amount >= state.amountRange!.start &&
                e.amount <= state.amountRange!.end,
          )
          .toList();
    }

    double thisIn = 0, thisEx = 0, lastTot = 0, filtIn = 0, filtEx = 0;
    final dailyMap = <int, double>{};

    for (final e in all) {
      final isIn = e.type == 'income';
      if (!e.date.isBefore(thisMonthStart) &&
          e.date.isBefore(DateTime(now.year, now.month + 1))) {
        if (isIn) {
          thisIn += e.amount;
        } else {
          thisEx += e.amount;
          if (e.date.month == now.month && e.date.year == now.year) {
            dailyMap[e.date.day] = (dailyMap[e.date.day] ?? 0) + e.amount;
          }
        }
      } else if (e.date.isAfter(lastMonthStart) &&
          e.date.isBefore(lastMonthEnd)) {
        lastTot += isIn ? e.amount : -e.amount;
      }
    }
    for (final e in filtered) {
      if (e.type == 'income') {
        filtIn += e.amount;
      } else {
        filtEx += e.amount;
      }
    }

    return state.copyWith(
      expenses: filtered,
      allExpenses: all,
      thisMonthTotal: thisIn - thisEx,
      thisMonthIncome: thisIn,
      thisMonthExpense: thisEx,
      lastMonthTotal: lastTot,
      filteredIncome: filtIn,
      filteredExpense: filtEx,
      dailySpending: List.generate(31, (i) => dailyMap[i + 1] ?? 0),
      isLoading: false,
    );
  }

  Future<String> addExpense({
    required double amount,
    String? categoryId,
    Object? projectId = _projectIdNotProvided,
    required DateTime date,
    String? note,
    String type = 'expense',
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Authentication required');
    final pid = identical(projectId, _projectIdNotProvided)
        ? state.currentProjectId
        : projectId as String?;
    final id = db.id();
    final now = DateTime.now().millisecondsSinceEpoch;
    final ops = <Operation>[
      ...db.tx['expenses'].create({
        'id': id,
        'creatorId': uid,
        'projectId': pid,
        'categoryId': categoryId,
        'amount': amount,
        'type': type,
        'date': date.millisecondsSinceEpoch,
        'note': note,
        'createdAt': now,
        'updatedAt': now,
      }).operations,
      ...db.tx['expenses'][id].link({
        'creator': uid,
        if (pid != null) 'project': pid,
        if (categoryId != null) 'category': categoryId,
      }).operations,
    ];
    await db.transact(ops);
    return id;
  }

  Future<void> updateExpense({
    required String id,
    required double amount,
    String? categoryId,
    required DateTime date,
    String? note,
    String type = 'expense',
  }) async {
    await db.transact(
      db.tx['expenses'][id].update({
        'amount': amount,
        'type': type,
        'categoryId': categoryId,
        'date': date.millisecondsSinceEpoch,
        'note': note,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    // ponytail: category link left as-is on edit; scalar categoryId is the
    // source of truth for the UI. Relink here if category-based perms appear.
  }

  Future<void> deleteExpense(String id) async {
    try {
      // shortcut: stored receipts remain after expense deletion; add server cleanup before enforcing storage retention.
      await db.transact(db.tx['expenses'][id].delete());
    } catch (e) {
      debugPrint('Error deleting expense: $e');
    }
  }

  @override
  Future<void> close() {
    _queryDispose?.call();
    _authSub.cancel();
    return super.close();
  }
}
