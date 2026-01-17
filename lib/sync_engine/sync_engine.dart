import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense/core/adapters/adapters.dart';
import 'package:expense/data/local/database.dart';
import 'package:logger/logger.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSync;
  final String? errorMessage;

  SyncState({required this.status, this.lastSync, this.errorMessage});
}

enum SyncConflictStrategy { lastWriteWins, localWins, remoteWins }

class TableSyncConfig {
  final String tableName;
  final String primaryKey;
  final String updatedAtColumn;
  final SyncConflictStrategy conflictStrategy;

  const TableSyncConfig({
    required this.tableName,
    this.primaryKey = 'id',
    this.updatedAtColumn = 'updated_at',
    this.conflictStrategy = SyncConflictStrategy.lastWriteWins,
  });
}

class SyncEngine {
  final LocalDatabaseAdapter localDb;
  final RemoteServiceAdapter remoteService;
  final Duration syncInterval;
  final _logger = Logger();

  final _syncStateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get syncState => _syncStateController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;
  final List<TableSyncConfig> tableConfigs;
  final Duration purgeInterval; // How often to check for purges
  final Duration purgeOlderThan; // How old a deleted item must be to be purged
  DateTime? _lastPurge;

  SyncEngine({
    required this.localDb,
    required this.remoteService,
    this.tableConfigs = const [],
    this.syncInterval = const Duration(seconds: 30),
    this.purgeInterval = const Duration(days: 1),
    this.purgeOlderThan = const Duration(days: 30),
  });

  void start() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        triggerSync();
      }
    });

    _syncTimer = Timer.periodic(syncInterval, (_) => triggerSync());
    _syncStateController.add(SyncState(status: SyncStatus.idle));
  }

  void stop() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _syncStateController.close();
  }

  Completer<void>? _syncCompleter;

  Future<void> triggerSync() async {
    if (_isSyncing) return _syncCompleter?.future;

    _isSyncing = true;
    _syncCompleter = Completer<void>();
    _syncStateController.add(SyncState(status: SyncStatus.syncing));

    try {
      await _pushUnits();
      await _pullUnits();

      // Periodic Purge
      if (_lastPurge == null ||
          DateTime.now().difference(_lastPurge!) > purgeInterval) {
        await _purgeDeletedItems();
        _lastPurge = DateTime.now();
      }

      _syncStateController.add(
        SyncState(status: SyncStatus.success, lastSync: DateTime.now()),
      );
    } catch (e, stack) {
      _logger.e('Sync failed', error: e, stackTrace: stack);
      _syncStateController.add(
        SyncState(status: SyncStatus.error, errorMessage: e.toString()),
      );
    } finally {
      _isSyncing = false;
      _syncCompleter?.complete();
      _syncCompleter = null;
    }
  }

  Future<void> _purgeDeletedItems() async {
    _logger.i('SyncEngine: Starting purge of old deleted items...');
    final cutoff = DateTime.now().subtract(purgeOlderThan);
    final userId = remoteService.currentUserId;

    if (userId == null) {
      _logger.w('SyncEngine: Cannot purge remote as userId is null');
    }

    for (final config in tableConfigs) {
      try {
        _logger.i('SyncEngine: Purging ${config.tableName}...');
        await localDb.purge(config.tableName, cutoff);
        if (userId != null) {
          await remoteService.purge(config.tableName, userId, cutoff);
        }
      } catch (e) {
        _logger.e('SyncEngine: Failed to purge ${config.tableName}', error: e);
      }
    }
    _logger.i('SyncEngine: Purge complete');
  }

  Future<void> _pushUnits() async {
    final queue = await localDb.getSyncQueue();

    for (final op in queue) {
      try {
        await _processOp(op);
        await localDb.removeFromSyncQueue(op.id);
      } catch (e) {
        _logger.w('Failed to process sync op ${op.id}', error: e);
        if (op.retryCount > 5) {
          await localDb.removeFromSyncQueue(op.id);
        } else {
          await localDb.incrementRetryCount(op.id);
          rethrow;
        }
      }
    }
  }

  Future<void> _processOp(SyncQueueData op) async {
    final table = op.targetTable;
    final rowId = op.rowId;

    // All operations (INSERT, UPDATE, and soft DELETE) are handled via upsert
    final localData = await localDb.getById(table, rowId);
    if (localData != null) {
      await remoteService.upsert(table, localData);
    }
  }

  Future<void> _pullUnits() async {
    final lastSync = DateTime.fromMillisecondsSinceEpoch(0);

    for (final config in tableConfigs) {
      _logger.i('SyncEngine: Pulling ${config.tableName}...');
      final remoteData = await remoteService.fetch(
        config.tableName,
        lastSync,
        updatedAtColumn: config.updatedAtColumn,
      );

      _logger.i(
        'SyncEngine: Found ${remoteData.length} records for ${config.tableName}',
      );

      for (final data in remoteData) {
        final id = data[config.primaryKey]?.toString();
        if (id == null) continue;

        // Conflict Resolution
        final localData = await localDb.getById(config.tableName, id);
        if (localData != null) {
          final shouldUpdate = _resolveConflict(config, localData, data);
          if (!shouldUpdate) continue;
        }

        await localDb.upsert(config.tableName, data);
      }
    }
  }

  bool _resolveConflict(
    TableSyncConfig config,
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    switch (config.conflictStrategy) {
      case SyncConflictStrategy.localWins:
        return false;
      case SyncConflictStrategy.remoteWins:
        return true;
      case SyncConflictStrategy.lastWriteWins:
        final localUpdated = _parseDate(local[config.updatedAtColumn]);
        final remoteUpdated = _parseDate(remote[config.updatedAtColumn]);
        return remoteUpdated.isAfter(localUpdated);
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
