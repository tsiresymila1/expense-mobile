import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/auth/auth_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/router.dart';
import 'package:expense/sync_engine/sync_engine.dart';
import 'package:expense/flavors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_builder_validators/localization/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseApp extends StatelessWidget {
  final AppDatabase database;
  final SyncEngine syncEngine;

  const ExpenseApp({
    super.key,
    required this.database,
    required this.syncEngine,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: database),
        RepositoryProvider.value(value: syncEngine),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(Supabase.instance.client)
              ..add(AuthSubscriptionRequested()),
          ),
          BlocProvider(create: (_) => SettingsBloc()),
          BlocProvider(
            create: (context) => ExpensesBloc(context.read<AppDatabase>())
              ..add(LoadExpenses()),
          ),
          BlocProvider(
            create: (context) => CategoriesBloc(context.read<AppDatabase>())
              ..add(LoadCategories()),
          ),
        ],
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return MaterialApp.router(
              title: F.title,
              debugShowCheckedModeBanner: false,
              localizationsDelegates: [
                ...context.localizationDelegates,
                FormBuilderLocalizationsDelegate()
              ],
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: state.themeMode,
              routerConfig: AppRouter.config,
              builder: (context, child) {
                return _flavorBanner(
                  child: child ?? const SizedBox.shrink(),
                  show: kDebugMode,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _flavorBanner({required Widget child, bool show = true}) => show
      ? Banner(
          location: BannerLocation.topStart,
          message: F.name,
          color: Colors.green.withAlpha(150),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.0,
            letterSpacing: 1.0,
          ),
          child: child,
        )
      : child;
}
