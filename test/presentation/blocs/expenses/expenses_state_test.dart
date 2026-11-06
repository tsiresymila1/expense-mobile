import 'package:flutter/material.dart';
import 'package:expense/presentation/blocs/expenses/expenses_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filter reset clears explicit null and retains omitted values', () {
    final range = DateTimeRange(
      start: DateTime(2026, 11),
      end: DateTime(2026, 12),
    );
    final state = ExpensesState(
      expenses: [],
      dateRange: range,
      amountRange: const RangeValues(10, 100),
    );
    expect(state.copyWith().dateRange, range);
    expect(
      state.copyWith(dateRange: null, amountRange: null).dateRange,
      isNull,
    );
    expect(
      state.copyWith(dateRange: null, amountRange: null).amountRange,
      isNull,
    );
  });
  test('copyWith can clear the project id for personal expenses', () {
    final state = ExpensesState(
      expenses: const [],
      currentProjectId: 'project-1',
    );

    final personalState = state.copyWith(currentProjectId: null);

    expect(personalState.currentProjectId, isNull);
  });
}
