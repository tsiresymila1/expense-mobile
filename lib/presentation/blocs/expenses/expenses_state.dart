import 'package:expense/data/local/database.dart';
import 'package:flutter/material.dart';

class ExpensesState {
  final List<LocalExpense> expenses;
  final double thisMonthTotal;
  final double thisMonthIncome;
  final double thisMonthExpense;
  final double lastMonthTotal;
  final double filteredIncome;
  final double filteredExpense;
  final List<double> dailySpending;
  final bool isLoading;
  final DateTimeRange? dateRange;
  final RangeValues? amountRange;
  final String? currentProjectId;

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
    this.currentProjectId,
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
    String? currentProjectId,
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
      dateRange: dateRange ?? this.dateRange,
      amountRange: amountRange ?? this.amountRange,
      currentProjectId: currentProjectId ?? this.currentProjectId,
    );
  }
}
