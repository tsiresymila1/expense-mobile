import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsState defaults', () {
    test('uses the system language and theme', () {
      const state = SettingsState();

      expect(state.language, 'system');
      expect(state.themeMode, ThemeMode.system);
      expect(state.currency, 'MGA');
    });

    test('uses system defaults when persisted values are absent', () {
      final state = SettingsState.fromJson(const <String, dynamic>{});

      expect(state.language, 'system');
      expect(state.themeMode, ThemeMode.system);
    });
  });
}
