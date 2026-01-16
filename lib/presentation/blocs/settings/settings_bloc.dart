import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_bloc.freezed.dart';
part 'settings_bloc.g.dart';

@freezed
class SettingsState with _$SettingsState {
  const SettingsState._();

  const factory SettingsState({
    @Default('en') String language,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default('USD') String currency,
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

abstract class SettingsEvent {}

class ChangeLanguage extends SettingsEvent {
  final String language;
  ChangeLanguage(this.language);
}

class ChangeTheme extends SettingsEvent {
  final ThemeMode themeMode;
  ChangeTheme(this.themeMode);
}

class ChangeCurrency extends SettingsEvent {
  final String currency;
  ChangeCurrency(this.currency);
}

class SettingsBloc extends HydratedBloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<ChangeLanguage>(
      (event, emit) => emit(state.copyWith(language: event.language)),
    );
    on<ChangeTheme>(
      (event, emit) => emit(state.copyWith(themeMode: event.themeMode)),
    );
    on<ChangeCurrency>(
      (event, emit) => emit(state.copyWith(currency: event.currency)),
    );
  }

  @override
  SettingsState? fromJson(Map<String, dynamic> json) =>
      SettingsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(SettingsState state) => state.toJson();
}
