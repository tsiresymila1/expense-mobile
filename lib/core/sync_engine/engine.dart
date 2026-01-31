import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense/core/sync_engine/adapters.dart';
import 'package:expense/data/local/database.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final String? remoteTableName;
  final String primaryKey;
  final ShouldPushCallback? shouldPush;
  final String updatedAtColumn;
  final SyncConflictStrategy conflictStrategy;
  final bool hasSoftDelete;
  final String userIdColumn;
  final bool pullOnly;

  const TableSyncConfig({
    required this.tableName,
    this.primaryKey = 'id',
    this.updatedAtColumn = 'updated_at',
    this.conflictStrategy = SyncConflictStrategy.lastWriteWins,
    this.hasSoftDelete = true,
    this.userIdColumn = 'user_id',
    this.pullOnly = false,
    this.remoteTableName,
    this.shouldPush,
  });

  String get remoteName => remoteTableName ?? tableName;
}

enum SyncStrategy { polling, realtime }

typedef ShouldPushCallback = Future<bool> Function(SyncQueueData op);

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
  bool _needsAnotherSync = false;
  final List<TableSyncConfig> tableConfigs;
  final Duration purgeInterval; // How often to check for purges
  final Duration purgeOlderThan; // How old a deleted item must be to be purged
  DateTime? _lastPurge;
  final SyncStrategy strategy;

  SyncEngine({
    required this.localDb,
    required this.remoteService,
    this.tableConfigs = const [],
    this.syncInterval = const Duration(seconds: 30),
    this.purgeInterval = const Duration(days: 1),
    this.purgeOlderThan = const Duration(days: 30),
    this.strategy = SyncStrategy.polling,
  });

  void start() {
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        triggerSync();
        if (strategy == SyncStrategy.realtime) {
          _startRealtimeSync();
        }
      } else {
        if (strategy == SyncStrategy.realtime) {
          _stopRealtimeSync();
        }
      }
    });

    if (strategy == SyncStrategy.polling) {
      _syncTimer = Timer.periodic(syncInterval, (_) => triggerSync());
    } else if (strategy == SyncStrategy.realtime) {
      _startRealtimeSync();
    }
    
    _syncStateController.add(SyncState(status: SyncStatus.idle));
    // Trigger initial sync immediately
    triggerSync();
  }
  
  void _startRealtimeSync() {
    _logger.i('Starting Realtime Sync...');
    for (final config in tableConfigs) {
      debugPrint('SYNC_ENGINE: Subscribing to ${config.remoteName}');
      remoteService.subscribeToChanges(config.remoteName, (payload) {
        _logger.i('Realtime event received for ${config.tableName}: $payload');
        triggerSync(); 
      });
    }
  }

  void _stopRealtimeSync() {
     _logger.i('Stopping Realtime Sync...');
     remoteService.unsubscribeAll();
  }

  void stop() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    if (strategy == SyncStrategy.realtime) {
      _stopRealtimeSync();
    }
    _syncStateController.close();
  }

  Completer<void>? _syncCompleter;

  Future<void> triggerSync() async {
    if (_isSyncing) {
      _logger.i('SyncEngine: Sync already in progress, scheduling re-sync.');
      _needsAnotherSync = true;
      return _syncCompleter?.future;
    }

    _isSyncing = true;
    _needsAnotherSync = false;
    _syncCompleter = Completer<void>();
    _syncStateController.add(SyncState(status: SyncStatus.syncing));

    try {
      final userId = remoteService.currentUserId;
      final baseline = DateTime.fromMillisecondsSinceEpoch(0);

      for (final config in tableConfigs) {
        _logger.i('--- Starting Sync for ${config.tableName} ---');
        
        // 1. Push local changes for this specific table
        try {
          await _pushUnitsForTable(config, userId);
        } catch (e) {
          _logger.e('SyncEngine: Push failed for ${config.tableName}', error: e);
          // Continue to pull even if push fails
        }

        // 2. Pull remote changes for this specific table
        try {
          await _pullUnitsForTable(config, userId, baseline);
        } catch (e) {
          _logger.e('SyncEngine: Pull failed for ${config.tableName}', error: e);
          rethrow; // Pull failures are considered critical for consistency
        }
      }

      // 3. Periodic Purge
      if (_lastPurge == null ||
          DateTime.now().difference(_lastPurge!) > purgeInterval) {
        await _purgeDeletedItems();
        _lastPurge = DateTime.now();
      }

      _syncStateController.add(
        SyncState(status: SyncStatus.success, lastSync: DateTime.now()),
      );
    } catch (e, stack) {
      _logger.e('SyncEngine: Sync process failed', error: e, stackTrace: stack);
      _syncStateController.add(
        SyncState(status: SyncStatus.error, errorMessage: e.toString()),
      );
    } finally {
      _isSyncing = false;
      _syncCompleter?.complete();
      _syncCompleter = null;

      // If a change happened while we were syncing, start again
      if (_needsAnotherSync) {
        _logger.i('SyncEngine: Running scheduled re-sync...');
        triggerSync();
      }
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
      if (!config.hasSoftDelete) continue;
      
      try {
        _logger.i('SyncEngine: Purging ${config.tableName}...');
        await localDb.purge(config.tableName, cutoff);
        if (userId != null) {
          await remoteService.purge(
            config.remoteName,
            userId,
            cutoff,
            userIdColumn: config.userIdColumn,
          );
        }
      } catch (e) {
        _logger.e('SyncEngine: Failed to purge ${config.tableName}', error: e);
      }
    }
    _logger.i('SyncEngine: Purge complete');
  }

  Future<void> _pushUnitsForTable(TableSyncConfig config, String? userId) async {
    final queue = (await localDb.getSyncQueue(userId: userId))
        .where((op) => op.targetTable == config.tableName)
        .toList();

    if (queue.isEmpty) return;
    _logger.i('SyncEngine: Pushing ${queue.length} ops for ${config.tableName}');

    for (final op in queue) {
      try {
        // Run pre-push validation hook
        if (config.shouldPush != null) {
          final shouldProceed = await config.shouldPush!(op);
          if (!shouldProceed) {
            _logger.w('Skipping push for ${op.targetTable} ${op.rowId}: Validation failed.');
            await localDb.removeFromSyncQueue(op.id);
            continue;
          }
        }

        await _processOp(op);
        await localDb.removeFromSyncQueue(op.id);
      } catch (e) {
        _logger.w('Failed to process sync op ${op.id}', error: e);
        if (e is PostgrestException && e.code == '23505') {
          await localDb.removeFromSyncQueue(op.id);
          continue;
        }
        if (op.retryCount > 5) {
          await localDb.removeFromSyncQueue(op.id);
        } else {
          await localDb.incrementRetryCount(op.id);
          // Don't rethrow here to allow other items/tables to proceed
        }
      }
    }
  }

  Future<void> _pullUnitsForTable(TableSyncConfig config, String? userId, DateTime baseline) async {
    _logger.i('SyncEngine: Pulling updates for ${config.tableName}...');
    
    // Get full queue again in case pushing cleared some items
    final queue = await localDb.getSyncQueue(userId: userId);

    final remoteData = await remoteService.fetch(
      config.remoteName,
      baseline,
      updatedAtColumn: config.updatedAtColumn,
    );

    int updatedCount = 0;
    int skippedCount = 0;

    for (final data in remoteData) {
      final id = data[config.primaryKey]?.toString();
      if (id == null) continue;

      final localData = await localDb.getById(config.tableName, id);
      if (localData != null) {
        final isPending = queue.any(
          (q) => q.targetTable == config.tableName && q.rowId == id,
        );

        if (!isPending) {
          await localDb.upsert(config.tableName, data);
          updatedCount++;
          continue;
        }

        final shouldUpdate = _resolveConflict(config, localData, data);
        if (!shouldUpdate) {
          skippedCount++;
          continue;
        }
      }

      await localDb.upsert(config.tableName, data);
      updatedCount++;
    }
    _logger.i('SyncEngine: Done ${config.tableName}. Upserted: $updatedCount, Skipped: $skippedCount');
  }

  Future<void> _processOp(SyncQueueData op) async {
    final table = op.targetTable;
    final rowId = op.rowId;

    // Resolve remote table name
    final config = tableConfigs.firstWhere(
      (c) => c.tableName == table,
      orElse:
          () => TableSyncConfig(
            tableName: table,
          ), // Fallback if no config found
    );
    final remoteTable = config.remoteName;

    if (op.operation == 'DELETE') {
      _logger.i('SyncEngine: Processing HARD DELETE for $table($remoteTable):$rowId');
      await remoteService.delete(remoteTable, rowId);
      return;
    }

    // All operations (INSERT, UPDATE, and soft DELETE) are handled via upsert
    final localData = await localDb.getById(table, rowId);
    if (localData != null) {
      await remoteService.upsert(remoteTable, localData);
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
        // Only skip remote if local is strictly newer
        return !localUpdated.isAfter(remoteUpdated);
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
