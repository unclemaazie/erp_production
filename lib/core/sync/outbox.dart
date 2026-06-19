import 'dart:convert';
import '../db/local_db.dart';
import '../supabase_config.dart';
import '../constants.dart';

class OutboxItem {
  final int? id;
  final String tableName;
  final String operation;
  final Map<String, dynamic> payload;
  final String? recordId;
  final DateTime createdAt;
  final int retryCount;
  final int synced;
  final String? errorMessage;

  OutboxItem({
    this.id,
    required this.tableName,
    required this.operation,
    required this.payload,
    this.recordId,
    required this.createdAt,
    this.retryCount = 0,
    this.synced = SyncStatus.pending,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'table_name': tableName,
        'operation': operation,
        'payload': jsonEncode(payload),
        'record_id': recordId,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
        'synced': synced,
        'error_message': errorMessage,
      };

  factory OutboxItem.fromMap(Map<String, dynamic> map) => OutboxItem(
        id: map['id'] as int?,
        tableName: map['table_name'] as String,
        operation: map['operation'] as String,
        payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
        recordId: map['record_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        retryCount: map['retry_count'] as int? ?? 0,
        synced: map['synced'] as int? ?? 0,
        errorMessage: map['error_message'] as String?,
      );
}

class Outbox {
  static const int maxRetries = 5;

  Future<void> queue({
    required String tableName,
    required String operation,
    required Map<String, dynamic> payload,
    String? recordId,
  }) async {
    final db = await LocalDB.instance;
    await db.insert('outbox', {
      'table_name': tableName,
      'operation': operation,
      'payload': jsonEncode(payload),
      'record_id': recordId,
      'synced': SyncStatus.pending,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<OutboxItem>> getPending() async {
    final db = await LocalDB.instance;
    final rows = await db.query(
      'outbox',
      where: 'synced = ? AND retry_count < ?',
      whereArgs: [SyncStatus.pending, maxRetries],
      orderBy: 'created_at ASC',
    );
    return rows.map(OutboxItem.fromMap).toList();
  }

  Future<List<OutboxItem>> getFailed() async {
    final db = await LocalDB.instance;
    final rows = await db.query(
      'outbox',
      where: 'synced = ? OR retry_count >= ?',
      whereArgs: [SyncStatus.error, maxRetries],
      orderBy: 'created_at DESC',
    );
    return rows.map(OutboxItem.fromMap).toList();
  }

  Future<void> markSynced(int id) async {
    final db = await LocalDB.instance;
    await db.update(
      'outbox',
      {'synced': SyncStatus.synced},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markError(int id, String message) async {
    final db = await LocalDB.instance;
    final existing = await db.query('outbox', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return;
    final retry = (existing.first['retry_count'] as int? ?? 0) + 1;
    await db.update(
      'outbox',
      {'synced': SyncStatus.error, 'error_message': message, 'retry_count': retry},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> retryFailed() async {
    final db = await LocalDB.instance;
    await db.update(
      'outbox',
      {'synced': SyncStatus.pending, 'retry_count': 0, 'error_message': null},
      where: 'synced = ?',
      whereArgs: [SyncStatus.error],
    );
  }

  Future<void> clearSynced() async {
    final db = await LocalDB.instance;
    await db.delete('outbox', where: 'synced = ?', whereArgs: [SyncStatus.synced]);
  }
}
