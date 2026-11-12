import 'package:expense/data/models/models.dart';
import 'package:flutter/material.dart';

const _currentProjectIdNotProvided = Object();

class ExpensesState {
  final List<Expense> expenses;
  /// Whole current-project list, ignoring [dateRange]/[amountRange]. v6 screens
  /// (Activity, Analysis) filter this locally so their filters stay independent.
  final List<Expense> allExpenses;
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
    this.allExpenses = const [],
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
    List<Expense>? expenses,
    List<Expense>? allExpenses,
    double? thisMonthTotal,
    double? thisMonthIncome,
    double? thisMonthExpense,
    double? lastMonthTotal,
    double? filteredIncome,
    double? filteredExpense,
    List<double>? dailySpending,
    bool? isLoading,
    Object? dateRange = _currentProjectIdNotProvided,
    Object? amountRange = _currentProjectIdNotProvided,
    Object? currentProjectId = _currentProjectIdNotProvided,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      allExpenses: allExpenses ?? this.allExpenses,
      thisMonthTotal: thisMonthTotal ?? this.thisMonthTotal,
      thisMonthIncome: thisMonthIncome ?? this.thisMonthIncome,
      thisMonthExpense: thisMonthExpense ?? this.thisMonthExpense,
      lastMonthTotal: lastMonthTotal ?? this.lastMonthTotal,
      filteredIncome: filteredIncome ?? this.filteredIncome,
      filteredExpense: filteredExpense ?? this.filteredExpense,
      dailySpending: dailySpending ?? this.dailySpending,
      isLoading: isLoading ?? this.isLoading,
      dateRange: identical(dateRange, _currentProjectIdNotProvided)
          ? this.dateRange
          : dateRange as DateTimeRange?,
      amountRange: identical(amountRange, _currentProjectIdNotProvided)
          ? this.amountRange
          : amountRange as RangeValues?,
      currentProjectId:
          identical(currentProjectId, _currentProjectIdNotProvided)
          ? this.currentProjectId
          : currentProjectId as String?,
    );
  }
}
