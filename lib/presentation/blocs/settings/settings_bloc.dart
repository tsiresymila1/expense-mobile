import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_bloc.freezed.dart';
part 'settings_bloc.g.dart';

@freezed
class SettingsState with _$SettingsState {
  const SettingsState._();

  const factory SettingsState({
    @Default('system') String language,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default('MGA') String currency,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);

  String get currencySymbol {
    switch (currency) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'MGA':
        return 'Ar';
      case 'USD':
        return '\$';
      default:
        return currency;
    }
  }
}

class SettingsCubit extends HydratedCubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void changeLanguage(String language) =>
      emit(state.copyWith(language: language));

  void changeTheme(ThemeMode themeMode) =>
      emit(state.copyWith(themeMode: themeMode));

  void changeCurrency(String currency) =>
      emit(state.copyWith(currency: currency));

  @override
  SettingsState? fromJson(Map<String, dynamic> json) =>
      SettingsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(SettingsState state) => state.toJson();
}
