import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/auth/auth_session_store.dart';
import 'package:expense/core/config.dart';
import 'package:expense/presentation/app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:path_provider/path_provider.dart';

Future<void> bootstrap(AppFlavor flavor) async {
  final WidgetsBinding widgetsBinding;
  if (kDebugMode) {
    widgetsBinding = MarionetteBinding.ensureInitialized();
  } else {
    widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  }
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: AppConfig.environmentFileFor(flavor));
  final config = AppConfig.fromEnvironment(
    flavor: flavor,
    environment: dotenv.env,
  );

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );

  final sessionStore = SecureAuthSessionStore();
  await _migrateLegacySession(sessionStore);

  final db = await InstantDB.init(
    appId: config.instantAppId,
    config: InstantConfig(
      syncEnabled: true,
      baseUrl: config.instantApiUri.toString(),
    ),
  );
  await AuthSessionRestorer(sessionStore).restore(
    verify: (token) async {
      await db.auth.verifyRefreshToken(refreshToken: token);
    },
  );

  FlutterNativeSplash.remove();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      useOnlyLangCode: true,
      child: ExpenseApp(db: db, config: config, sessionStore: sessionStore),
    ),
  );
}

Future<void> _migrateLegacySession(AuthSessionStore sessionStore) async {
  final secureToken = await sessionStore.readRefreshToken();
  final legacy = HydratedBloc.storage.read('auth_session');
  final legacyValue = legacy is Map ? legacy['refreshToken'] : null;
  final legacyToken = legacyValue is String ? legacyValue : null;

  if (secureToken == null && legacyToken != null && legacyToken.isNotEmpty) {
    await sessionStore.writeRefreshToken(legacyToken);
  }
  await HydratedBloc.storage.delete('auth_session');
}
