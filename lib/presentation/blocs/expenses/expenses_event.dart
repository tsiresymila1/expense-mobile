import 'package:flutter/material.dart';

abstract class ExpensesEvent {}

class LoadExpenses extends ExpensesEvent {
  final DateTimeRange? dateRange;
  final RangeValues? amountRange;
  final String? projectId;
  LoadExpenses({this.dateRange, this.amountRange, this.projectId});
}

class AddExpense extends ExpensesEvent {
  final double amount;
  final String? categoryId;
  final String? projectId;
  final DateTime date;
  final String? note;
  final String type; // 'expense' or 'income'
  AddExpense({
    required this.amount,
    this.categoryId,
    this.projectId,
    required this.date,
    this.note,
    this.type = 'expense',
  });
}

class UpdateExpense extends ExpensesEvent {
  final String id;
  final double amount;
  final String? categoryId;
  final DateTime date;
  final String? note;
  final String type; // 'expense' or 'income'
  UpdateExpense({
    required this.id,
    required this.amount,
    this.categoryId,
    required this.date,
    this.note,
    this.type = 'expense',
  });
}

class DeleteExpense extends ExpensesEvent {
  final String id;
  DeleteExpense(this.id);
}
