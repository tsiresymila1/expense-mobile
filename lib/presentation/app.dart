import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/auth/auth_session_store.dart';
import 'package:expense/core/auth/google_oauth_client.dart';
import 'package:expense/core/config.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/auth/auth_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:form_builder_validators/localization/l10n.dart';

class ExpenseApp extends StatefulWidget {
  final InstantDB db;
  final AppConfig config;
  final AuthSessionStore sessionStore;

  const ExpenseApp({
    super.key,
    required this.db,
    required this.config,
    required this.sessionStore,
  });

  @override
  State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  late final _router = AppRouter.config(widget.db);
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = widget.db;
    final config = widget.config;
    final sessionStore = widget.sessionStore;
    return InstantProvider(
      db: db,
      child: MultiRepositoryProvider(
        providers: [RepositoryProvider.value(value: db)],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AuthCubit(
                db,
                sessionStore,
                googleOAuthClient: config.isGoogleAuthEnabled
                    ? GoogleOAuthClient(
                        db: db,
                        clientName: config.googleOAuthClientName!,
                        redirectUri: config.googleOAuthRedirectUri!,
                      )
                    : null,
              ),
            ),
            BlocProvider(create: (_) => SettingsCubit()),
            BlocProvider(create: (_) => ProjectsCubit(db: db)),
            BlocProvider(create: (_) => ExpensesCubit(db)),
            BlocProvider(create: (_) => CategoriesCubit(db)),
          ],
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              return MaterialApp.router(
                title: config.appName,
                debugShowCheckedModeBanner: false,
                localizationsDelegates: [
                  ...context.localizationDelegates,
                  FormBuilderLocalizationsDelegate(),
                ],
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: state.themeMode,
                routerConfig: _router,
                builder: (context, child) {
                  return _flavorBanner(
                    child: child ?? const SizedBox.shrink(),
                    flavorName: config.flavorName,
                    show: kDebugMode && config.isDevelopment,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _flavorBanner({
  required Widget child,
  required String flavorName,
  bool show = true,
}) => show
    ? Banner(
        location: BannerLocation.topStart,
        message: flavorName,
        color: Colors.green.withAlpha(150),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12.0,
          letterSpacing: 1.0,
        ),
        child: child,
      )
    : child;
