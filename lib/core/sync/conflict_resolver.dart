import 'dart:convert';
import '../db/local_db.dart';

enum ConflictStrategy { serverWins, clientWins, manual }

class ConflictResolver {
  static ConflictStrategy defaultStrategy = ConflictStrategy.serverWins;

  static Future<void> resolve({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> serverData,
    required Map<String, dynamic> localData,
    ConflictStrategy? strategy,
  }) async {
    final s = strategy ?? defaultStrategy;
    final db = await LocalDB.instance;

    switch (s) {
      case ConflictStrategy.serverWins:
        await db.update(
          tableName,
          {...serverData, 'sync_status': 1},
          where: 'id = ?',
          whereArgs: [recordId],
        );
        break;
      case ConflictStrategy.clientWins:
        await db.update(
          tableName,
          {...localData, 'sync_status': 0},
          where: 'id = ?',
          whereArgs: [recordId],
        );
        break;
      case ConflictStrategy.manual:
        await db.insert('conflicts', {
          'table_name': tableName,
          'record_id': recordId,
          'server_data': jsonEncode(serverData),
          'local_data': jsonEncode(localData),
          'resolved': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
        break;
    }
  }
}
