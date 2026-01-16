import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}

enum AppFlavor { dev, prod }

class FlavorConfig {
  final AppFlavor flavor;
  final String name;

  static FlavorConfig? _instance;

  factory FlavorConfig({required AppFlavor flavor, required String name}) {
    _instance ??= FlavorConfig._internal(flavor, name);
    return _instance!;
  }

  FlavorConfig._internal(this.flavor, this.name);

  static FlavorConfig get instance => _instance!;

  static bool get isDev => _instance?.flavor == AppFlavor.dev;
}
