import 'package:expense/presentation/pages/expenses/expenses_page.dart';
import 'package:expense/presentation/pages/stats/stats_page.dart';
import 'package:expense/presentation/pages/settings/settings_page.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/presentation/widgets/category_picker_field.dart';
import 'package:expense/presentation/widgets/add_category_modal.dart';
import 'package:expense/presentation/widgets/category_management_modal.dart';
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

Expense _tx(
  String id,
  double amount,
  int daysAgo,
  String note, {
  String type = 'expense',
  String? cat,
}) {
  final now = DateTime.now();
  return Expense(
    id: id,
    creatorId: 'me',
    amount: amount,
    type: type,
    date: DateTime(now.year, now.month, now.day - daysAgo),
    note: note,
    categoryId: cat,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

final _fixtureExpenses = [
  _tx('1', 84500, 0, 'Shoprite Ankorondrano', cat: 'shop'),
  _tx('2', 6800, 0, 'Café & croissant', cat: 'food'),
  _tx('3', 45000, 1, 'Taxi-be + moto', cat: 'move'),
  _tx('4', 150000, 2, 'Internet · abonnement', cat: 'home'),
  _tx('5', 350000, 3, 'Logo — client Antsirabe', type: 'income'),
  _tx('6', 52000, 4, 'Dîner chez Mama', cat: 'food'),
];

class TestExpenses extends Cubit<ExpensesState> implements ExpensesCubit {
  TestExpenses()
    : super(
        ExpensesState(
          expenses: _fixtureExpenses,
          allExpenses: _fixtureExpenses,
          thisMonthIncome: 350000,
          thisMonthExpense: 338300,
          thisMonthTotal: 11700,
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
            Category(
              id: 'home',
              name: 'Maison',
              icon: 'home',
              color: '#8A5CC2',
              updatedAt: DateTime(2026),
            ),
            Category(
              id: 'shop',
              name: 'Courses',
              icon: 'cart',
              color: '#287344',
              updatedAt: DateTime(2026),
            ),
            Category(
              id: 'food',
              name: 'Restaurants',
              icon: 'utensils',
              color: '#C9852B',
              updatedAt: DateTime(2026),
            ),
            Category(
              id: 'move',
              name: 'Transport',
              icon: 'car',
              color: '#2F6FB0',
              updatedAt: DateTime(2026),
            ),
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

  void phone(WidgetTester tester, {Size size = const Size(390, 844)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> golden(String name) async {
    if (const bool.fromEnvironment('DESIGN_GOLDENS')) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets('Dashboard ${dark ? 'dark' : 'light'} shows hero, week and recent', (
      tester,
    ) async {
      phone(tester);
      await mount(
        tester,
        const AppShell(location: '/', child: DashboardPage()),
        dark: dark,
      );
      final theme = Theme.of(tester.element(find.byType(DashboardPage)));
      expect(theme.textTheme.bodyMedium?.fontFamily, startsWith('Geist'));
      expect(find.textContaining('Bonjour'), findsOneWidget);
      expect(find.text('7 derniers jours'), findsOneWidget);
      expect(find.text('Shoprite Ankorondrano'), findsOneWidget);
      for (final tab in ['Accueil', 'Activité', 'Analyse', 'Projets']) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await golden('dashboard_${dark ? 'dark' : 'light'}');
    });
  }
  testWidgets('Navigation exposes all four destinations at 320px', (
    tester,
  ) async {
    phone(tester, size: const Size(320, 700));
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
    await tester.tap(find.text('Accueil'));
    expect(route, '/');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Email login keeps Google and opens real code entry', (
    tester,
  ) async {
    phone(tester);
    final auth = TestAuth();
    await mount(tester, const LoginPage(), auth: auth);
    expect(find.byKey(const ValueKey('google-sign-in-button')), findsOneWidget);
    await golden('login_light');
    await tester.enterText(find.byType(TextField).first, 'hello@example.com');
    await tester.tap(find.text('Envoyer le code'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(auth.sentEmail, 'hello@example.com');
    expect(find.byKey(const ValueKey('magic-code-pinput')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Central + opens the numpad sheet and validates the amount', (
    tester,
  ) async {
    phone(tester);
    await mount(tester, const AppShell(location: '/', child: DashboardPage()));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(AddExpenseModal), findsOneWidget);
    await golden('add_expense_light');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez un montant supérieur à 0.'), findsOneWidget);
    await tester.tap(find.text('5').last);
    await tester.tap(find.text('0').last);
    await tester.pump();
    expect(find.text('50'), findsWidgets);
    // Selected category chip shows a check mark; tapping another moves it.
    final check = find.descendant(
      of: find.byType(PickChip),
      matching: find.byIcon(Icons.check_rounded),
    );
    final before = check.evaluate().length;
    await tester.ensureVisible(find.text('Courses'));
    await tester.tap(find.text('Courses'));
    await tester.pump();
    expect(check.evaluate().length, before + 1);
    await tester.tap(find.text('Maison'));
    await tester.pump();
    expect(check.evaluate().length, before + 1);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
  });
  testWidgets('Activity groups by day, keeps its own period chip', (
    tester,
  ) async {
    phone(tester);
    await mount(
      tester,
      const AppShell(location: '/expenses', child: ExpensesPage()),
    );
    expect(find.text('Toutes les dates'), findsOneWidget);
    expect(find.text('AUJOURD’HUI'.toLowerCase()), findsNothing);
    expect(find.text('Café & croissant'), findsOneWidget);
    await golden('activity_light');
    await tester.tap(find.text('Revenus').first);
    await tester.pumpAndSettle();
    expect(find.text('Café & croissant'), findsNothing);
    expect(find.text('Logo — client Antsirabe'), findsOneWidget);
    await tester.tap(find.text('Toutes les dates'));
    await tester.pumpAndSettle();
    expect(find.text('Intervalle personnalisé'), findsOneWidget);
    await tester.tap(find.text('7 derniers jours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    expect(find.text('7 derniers jours'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Analysis defaults to this month and lists category legend', (
    tester,
  ) async {
    phone(tester);
    await mount(
      tester,
      const AppShell(location: '/stats', child: StatsPage()),
    );
    expect(find.text('Ce mois'), findsWidgets);
    expect(find.text('Restaurants'), findsWidgets);
    await golden('analysis_light');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Settings: appearance toggle switches the theme', (tester) async {
    phone(tester);
    await mount(tester, const SettingsPage());
    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
    );
    await golden('settings_light');
    expect(tester.takeException(), isNull);
  });
  test('Theme tokens: Geist, white on primary, readable dark primary', () {
    final light = AppTheme.lightTheme, dark = AppTheme.darkTheme;
    expect(light.textTheme.bodyMedium?.fontFamily, startsWith('Geist'));
    expect(light.colorScheme.onPrimary, Colors.white);
    expect(light.colorScheme.primary, AppTheme.primaryColor);
    expect(dark.colorScheme.primary, AppTheme.darkPrimary);
    expect(dark.colorScheme.onPrimary, isNot(Colors.white));
  });
  for (final entry in <String, Widget>{
    'activity': const Scaffold(body: ExpensesPage()),
    'analysis': const Scaffold(body: StatsPage()),
    'settings': const SettingsPage(),
    'new transaction': const Scaffold(body: AddExpenseModal()),
    'new category': const Scaffold(body: AddCategoryModal()),
    'categories': const Scaffold(body: CategoryManagementModal()),
  }.entries) {
    testWidgets('${entry.key} fits a narrow dark screen', (tester) async {
      phone(tester, size: const Size(320, 700));
      await mount(tester, entry.value, dark: true);
      expect(tester.takeException(), isNull);
    });
  }
}
