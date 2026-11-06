import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:expense/presentation/widgets/settings_widgets.dart';
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
        final theme = Theme.of(tester.element(find.byType(DashboardPage)));
        expect(theme.textTheme.bodyMedium?.fontFamily, startsWith('ABeeZee'));
        expect(
          theme.textTheme.headlineMedium?.fontFamily,
          startsWith('ABeeZee'),
        );
        expect(find.text('G-spend'), findsOneWidget);
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
  testWidgets('V5 entry covers shell and returns to home', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, const AppShell(location: '/', child: DashboardPage()));
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(AddExpenseModal), findsOneWidget);
    expect(find.byType(ExpenseNavigation), findsNothing);
    expect(find.text('G-spend'), findsNothing);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseNavigation), findsOneWidget);
  });
  for (final entry in <String, Widget>{
    '/expenses': const ExpensesPage(),
    '/stats': const StatsPage(),
  }.entries) {
    testWidgets('Expressive ${entry.key} owns its header', (tester) async {
      await mount(tester, AppShell(location: entry.key, child: entry.value));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('G-spend'), findsNothing);
      expect(find.byTooltip('Thème'), findsNothing);
      expect(
        find.byType(FloatingActionButton),
        entry.key == '/expenses' ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
  test('Expressive titles and dropdown typography share the theme scale', () {
    final theme = AppTheme.lightTheme;
    expect(
      theme.appBarTheme.titleTextStyle?.fontSize,
      theme.textTheme.titleLarge?.fontSize,
    );
    expect(
      theme.appBarTheme.titleTextStyle?.fontFamily,
      theme.textTheme.titleLarge?.fontFamily,
    );
    expect(
      theme.appBarTheme.titleTextStyle?.fontWeight,
      theme.textTheme.titleLarge?.fontWeight,
    );
    expect(
      theme.dropdownMenuTheme.textStyle?.fontSize,
      theme.textTheme.bodyMedium?.fontSize,
    );
    expect(theme.colorScheme.onPrimary, Colors.white);
  });
  for (final dark in [false, true]) {
    testWidgets('Filter sheet has an opaque surface with keyboard ($dark)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        const AppShell(location: '/expenses', child: ExpensesPage()),
        dark: dark,
      );
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      final context = tester.element(find.byType(BottomSheet));
      expect(
        sheet.backgroundColor ??
            Theme.of(context).bottomSheetTheme.backgroundColor,
        Theme.of(context).colorScheme.surface,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
    });
  }
  testWidgets('Project sheet keeps text away from its edges', (tester) async {
    await mount(tester, const AppShell(location: '/', child: DashboardPage()));
    await tester.tap(
      find.descendant(
        of: find.byType(ProjectContext),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    final tile = find
        .descendant(of: sheet, matching: find.byType(ListTile))
        .first;
    final label = find.descendant(of: tile, matching: find.byType(Text)).first;
    expect(
      tester.getTopLeft(label).dx - tester.getTopLeft(sheet).dx,
      greaterThanOrEqualTo(20),
    );
    expect(tester.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    testWidgets('Amount stays readable before and after focus ($dark)', (
      tester,
    ) async {
      await mount(tester, const Scaffold(body: AddExpenseModal()), dark: dark);
      final amount = find.byWidgetPredicate(
        (w) => w is FormBuilderTextField && w.name == 'amount',
      );
      final field = tester.widget<FormBuilderTextField>(amount);
      expect(field.style?.fontSize, 14);
      expect(field.decoration.filled, isTrue);
      expect(field.decoration.border, isA<OutlineInputBorder>());
      expect(
        (field.decoration.contentPadding! as EdgeInsets).left,
        greaterThanOrEqualTo(16),
      );
      expect(field.decoration.suffixText, isNotEmpty);
      await tester.tap(amount);
      await tester.enterText(amount, '5000');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Settings rows keep horizontal inset inside cards', (
    tester,
  ) async {
    await mount(tester, const SettingsPage());
    final row = find.byType(SettingsListTile).first;
    final label = find.descendant(of: row, matching: find.byType(Text)).first;
    expect(
      tester.getTopLeft(label).dx - tester.getTopLeft(row).dx,
      greaterThanOrEqualTo(20),
    );
  });
  testWidgets('Activity exposes filters only in its app bar', (tester) async {
    await mount(tester, const ExpensesPage());
    expect(find.byIcon(Icons.filter_list), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Gérer les catégories'), findsNothing);
  });
  testWidgets('V5 secondary page has no shared header or tabs', (tester) async {
    await mount(
      tester,
      const AppShell(location: '/settings', child: SettingsPage()),
    );
    expect(find.byType(ExpenseNavigation), findsNothing);
    expect(find.text('G-spend'), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
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
