import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/config.dart';
import 'package:expense/data/adapters/drift_local_database_adapter.dart';
import 'package:expense/data/adapters/supabase_remote_service_adapter.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/app.dart';
import 'package:expense/sync_engine/sync_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';


import 'flavors.dart';

Future<void> main() async {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await EasyLocalization.ensureInitialized();

  // Load flavor and initialize F.appFlavor
  const flavorStr = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  F.appFlavor = Flavor.values.firstWhere(
    (e) => e.name == flavorStr,
    orElse: () => Flavor.dev,
  );

  // Load environment variables based on flavor
  await dotenv.load(fileName: '.env.${F.name}');

  FlavorConfig(
    flavor: F.appFlavor == Flavor.prod ? AppFlavor.prod : AppFlavor.dev,
    name: F.title,
  );

  // Initialize HydratedBloc
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Initialize Local Database
  final database = AppDatabase();

  // Initialize Adapters
  final localDbAdapter = DriftLocalDatabaseAdapter(database);
  final remoteServiceAdapter = SupabaseRemoteServiceAdapter(
    Supabase.instance.client,
  );

  // Initialize Sync Engine
  final syncEngine = SyncEngine(
    localDb: localDbAdapter,
    remoteService: remoteServiceAdapter,
    tableConfigs: [
      TableSyncConfig(tableName: 'expenses'),
      TableSyncConfig(tableName: 'categories'),
      TableSyncConfig(tableName: 'projects', userIdColumn: 'owner_id'),
      TableSyncConfig(tableName: 'project_members', hasSoftDelete: false),
    ],
  );
  syncEngine.start();
  FlutterNativeSplash.remove();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ExpenseApp(database: database, syncEngine: syncEngine),
    ),
  );
}
