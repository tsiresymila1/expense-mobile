import 'package:expense/presentation/pages/expenses/expenses_page.dart';
import 'package:expense/presentation/pages/stats/stats_page.dart';
import 'package:expense/presentation/pages/settings/settings_page.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/presentation/widgets/add_category_modal.dart';
import 'package:expense/presentation/widgets/category_management_modal.dart';
import 'package:expense/presentation/widgets/expense_filter_modal.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/auth/auth_bloc.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/pages/dashboard/dashboard_page.dart';
import 'package:expense/presentation/pages/auth/login_page.dart';
import 'package:expense/presentation/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class FixtureLoader extends AssetLoader {
  const FixtureLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}

class TestExpenses extends Cubit<ExpensesState> implements ExpensesCubit {
  TestExpenses()
    : super(
        ExpensesState(
          expenses: [
            Expense(
              id: '1',
              creatorId: 'me',
              amount: 150000,
              type: 'expense',
              date: DateTime(2026, 11, 5),
              note: 'Internet · abonnement',
              categoryId: 'home',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          ],
          thisMonthIncome: 2400000,
          thisMonthExpense: 525000,
          thisMonthTotal: 1875000,
          dailySpending: List.generate(31, (i) => i == 4 ? 150000 : 0),
        ),
      );
  @override
  void loadExpenses({
    Object? dateRange,
    Object? amountRange,
    Object? projectId,
  }) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestCategories extends Cubit<CategoriesState> implements CategoriesCubit {
  TestCategories()
    : super(
        CategoriesState(
          categories: [
            Category(id: 'home', name: 'Maison', updatedAt: DateTime(2026)),
          ],
        ),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestProjects extends Cubit<ProjectsState> implements ProjectsCubit {
  TestProjects() : super(ProjectsState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestSettings extends Cubit<SettingsState> implements SettingsCubit {
  TestSettings() : super(const SettingsState());
  @override
  void changeTheme(ThemeMode mode) => emit(state.copyWith(themeMode: mode));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAuth extends Cubit<AppAuthState> implements AuthCubit {
  TestAuth()
    : super(AppAuthState(AuthStatus.unauthenticated, displayName: 'Tsiry'));
  String? sentEmail;
  @override
  bool get isGoogleSignInAvailable => true;
  @override
  Future<void> sendMagicCode(String email) async {
    sentEmail = email;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  Future<void> mount(
    WidgetTester tester,
    Widget page, {
    bool dark = false,
    TestAuth? auth,
  }) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('fr'), Locale('en')],
        path: 'assets/translations',
        assetLoader: const FixtureLoader(),
        startLocale: const Locale('fr'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider<ExpensesCubit>(create: (_) => TestExpenses()),
              BlocProvider<CategoriesCubit>(create: (_) => TestCategories()),
              BlocProvider<ProjectsCubit>(create: (_) => TestProjects()),
              BlocProvider<SettingsCubit>(create: (_) => TestSettings()),
              BlocProvider<AuthCubit>(create: (_) => auth ?? TestAuth()),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: page,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await GoogleFonts.pendingFonts();
      await precacheImage(
        const AssetImage('assets/images/google_g.png'),
        tester.element(find.byType(MaterialApp)),
      );
    });
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets(
      'Dashboard ${dark ? 'dark' : 'light'} matches mobile layout without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(
          tester,
          const AppShell(location: '/', child: DashboardPage()),
          dark: dark,
        );
        expect(find.text('expense'), findsOneWidget);
        expect(find.text('Accueil'), findsOneWidget);
        expect(find.text('Activité'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('DESIGN_GOLDENS')) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/dashboard_${dark ? 'dark' : 'light'}.png',
            ),
          );
        }
      },
    );
  }
  testWidgets('Navigation exposes all four destinations at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? route;
    await mount(
      tester,
      Scaffold(
        bottomNavigationBar: ExpenseNavigation(
          location: '/',
          onSelect: (v) => route = v,
        ),
      ),
    );
    await tester.tap(find.text('Activité'));
    expect(route, '/expenses');
    await tester.tap(find.text('Analyse'));
    expect(route, '/stats');
    await tester.tap(find.text('Projets'));
    expect(route, '/projects');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Email login keeps Google and opens real code entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = TestAuth();
    await mount(tester, const LoginPage(), auth: auth);
    expect(find.byKey(const ValueKey('google-sign-in-button')), findsOneWidget);
    if (const bool.fromEnvironment('DESIGN_GOLDENS')) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/login_light.png'),
      );
    }
    await tester.enterText(find.byType(TextField).first, 'hello@example.com');
    await tester.tap(find.text('Envoyer le code'));
    await tester.pumpAndSettle();
    expect(auth.sentEmail, 'hello@example.com');
    expect(find.byKey(const ValueKey('magic-code-pinput')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final entry in <String, Widget>{
    'activity': const ExpensesPage(),
    'analysis': const StatsPage(),
    'settings': const SettingsPage(),
    'new transaction': const Scaffold(body: AddExpenseModal()),
    'new category': const Scaffold(body: AddCategoryModal()),
    'categories': const Scaffold(body: CategoryManagementModal()),
    'filters': const Scaffold(body: ExpenseFilterModal(currencySymbol: 'Ar')),
  }.entries) {
    testWidgets('${entry.key} fits a narrow dark screen', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, entry.value, dark: true);
      expect(tester.takeException(), isNull);
    });
  }
}
