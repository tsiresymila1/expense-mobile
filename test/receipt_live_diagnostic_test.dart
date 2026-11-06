import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:uuid/uuid.dart';

// Opt in with --dart-define=LIVE_RECEIPT_TEST=true; creates and removes isolated test records.
void main() {
  test(
    'receipt upload, association and client/server retrieval',
    () async {
      HttpOverrides.global = null;
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final lines = File(
        '${Platform.environment['HOME']}/.config/instantdb/expense.env',
      ).readAsLinesSync();
      final config = {
        for (final l in lines)
          l.split('=').first.replaceFirst('export ', ''): l
              .substring(l.indexOf('=') + 1)
              .replaceAll("'", ''),
      };
      final app = config['INSTANT_APP_ID']!,
          base = config['INSTANT_CLI_API_URI']!;
      final admin = Dio(
        BaseOptions(
          baseUrl: base,
          headers: {
            'Authorization': 'Bearer ${config['INSTANT_CLI_AUTH_TOKEN']}',
            'App-Id': app,
          },
        ),
      );
      final uid = const Uuid().v4(), expense = const Uuid().v4();
      final path = '$uid/$expense/${const Uuid().v4()}/test.txt';
      final temp = Directory.systemTemp.createTempSync('receipt-sdk-');
      final result = await admin.post(
        '/admin/refresh_tokens',
        data: {'id': uid},
      );
      InstantDB? db;
      try {
        db = await InstantDB.init(
          appId: app,
          config: InstantConfig(baseUrl: base, persistenceDir: temp.path),
        );
        await db.auth.verifyRefreshToken(
          refreshToken: result.data['user']['refresh_token'],
        );
        await Future<void>.delayed(const Duration(seconds: 3));
        final deadline = DateTime.now().add(const Duration(seconds: 15));
        while (db.connectionStatus.value != ConnectionStatus.authenticated &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        await admin.post(
          '/admin/transact',
          data: {
            'steps': [
              [
                'update',
                'expenses',
                expense,
                {
                  'creatorId': uid,
                  'amount': 1,
                  'type': 'expense',
                  'date': DateTime.now().millisecondsSinceEpoch,
                  'createdAt': DateTime.now().millisecondsSinceEpoch,
                  'updatedAt': DateTime.now().millisecondsSinceEpoch,
                },
              ],
              [
                'link',
                'expenses',
                expense,
                {'creator': uid},
              ],
            ],
          },
        );
        final signal = db.query({
          r'$files': {
            'where': {
              'path': {r'$like': '%/$expense/%'},
            },
          },
        });
        await Future<void>.delayed(const Duration(seconds: 3));
        final uploaded = await db.storage.uploadFile(
          path,
          Uint8List.fromList([1, 2, 3]),
          contentType: 'application/octet-stream',
        );
        await db.transact(
          db.tx['expenses'][expense].update({'files': uploaded.id}),
        );
        await Future<void>.delayed(const Duration(seconds: 10));
        expect(signal.value.hasError, isFalse);
        expect(signal.value.data?[r'$files'], hasLength(1));
        expect((signal.value.data?[r'$files'] as List).single['path'], path);
        final check = await admin.post(
          '/admin/query',
          data: {
            'query': {
              'expenses': {
                r'$': {
                  'where': {'id': expense},
                },
                'files': {},
              },
            },
          },
        );
        expect((check.data['expenses'] as List).single['files'], hasLength(1));
      } finally {
        await db?.dispose();
        await admin.delete(
          '/admin/storage/files',
          queryParameters: {'filename': path},
        );
        await admin.post(
          '/admin/transact',
          data: {
            'steps': [
              ['delete', 'expenses', expense],
            ],
          },
        );
        await admin.delete('/admin/users', queryParameters: {'id': uid});
        temp.deleteSync(recursive: true);
      }
    },
    skip: !const bool.fromEnvironment('LIVE_RECEIPT_TEST'),
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
