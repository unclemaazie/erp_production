import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../db/local_db.dart';
import '../supabase_config.dart';
import '../constants.dart';
import 'outbox.dart';
import 'conflict_resolver.dart';

class SyncEngine extends ChangeNotifier {
  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSync;
  int _pendingCount = 0;

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastSync => _lastSync;
  int get pendingCount => _pendingCount;

  final _outbox = Outbox();
  final _tables = [
    'customers',
    'products',
    'warehouses',
    'inventory',
    'invoices',
    'invoice_line_items',
    'payments',
    'vehicles',
    'fleet_maintenance',
    'fleet_trips',
    'employees',
    'payroll_runs',
    'payslips',
    'expenses',
    'journal_entries',
  ];

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    if (!await isOnline) {
      _lastError = 'No internet connection';
      notifyListeners();
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      _lastError = 'Supabase not configured';
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      await _pushOutbox();
      await _pullChanges();
      await _updateMeta();
      _lastSync = DateTime.now();
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) print('Sync error: \$e');
    } finally {
      _isSyncing = false;
      await _refreshPendingCount();
      notifyListeners();
    }
  }

  Future<void> _pushOutbox() async {
    final pending = await _outbox.getPending();
    for (final item in pending) {
      try {
        final client = SupabaseConfig.client;
        switch (item.operation) {
          case 'INSERT':
            await client.from(item.tableName).insert(item.payload);
            break;
          case 'UPDATE':
            await client.from(item.tableName).update(item.payload).eq('id', item.recordId);
            break;
          case 'DELETE':
            await client.from(item.tableName).delete().eq('id', item.recordId);
            break;
        }
        await _outbox.markSynced(item.id!);
      } catch (e) {
        await _outbox.markError(item.id!, e.toString());
      }
    }
  }

  Future<void> _pullChanges() async {
    final db = await LocalDB.instance;
    for (final table in _tables) {
      try {
        final meta = await db.query(
          'sync_metadata',
          where: 'table_name = ?',
          whereArgs: [table],
        );
        final lastSync = meta.isNotEmpty ? meta.first['last_sync_at'] as String? : null;

        var query = SupabaseConfig.client.from(table).select();
        if (lastSync != null) {
          query = query.gt('updated_at', lastSync);
        }
        final remoteRows = await query.limit(1000);

        for (final row in remoteRows) {
          final id = row['id'] as String?;
          if (id == null) continue;

          final local = await db.query(table, where: 'id = ?', whereArgs: [id]);
          if (local.isEmpty) {
            await db.insert(table, {...row, 'sync_status': 1});
          } else {
            final localRow = local.first;
            final localSync = localRow['sync_status'] as int? ?? 0;
            if (localSync == SyncStatus.pending) {
              // Local uncommitted changes exist — potential conflict
              await ConflictResolver.resolve(
                tableName: table,
                recordId: id,
                serverData: Map<String, dynamic>.from(row),
                localData: Map<String, dynamic>.from(localRow),
              );
            } else {
              await db.update(table, {...row, 'sync_status': 1}, where: 'id = ?', whereArgs: [id]);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Pull error for \$table: \$e');
      }
    }
  }

  Future<void> _updateMeta() async {
    final db = await LocalDB.instance;
    final now = DateTime.now().toIso8601String();
    for (final table in _tables) {
      await db.insert(
        'sync_metadata',
        {'table_name': table, 'last_sync_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _refreshPendingCount() async {
    final pending = await _outbox.getPending();
    _pendingCount = pending.length;
  }

  Future<void> queueChange({
    required String tableName,
    required String operation,
    required Map<String, dynamic> payload,
    String? recordId,
  }) async {
    await _outbox.queue(
      tableName: tableName,
      operation: operation,
      payload: payload,
      recordId: recordId ?? payload['id'] as String?,
    );
    await _refreshPendingCount();
    notifyListeners();
  }
}
