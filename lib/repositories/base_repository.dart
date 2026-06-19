import '../core/db/local_db.dart';
import '../core/sync/sync_engine.dart';

abstract class BaseRepository<T> {
  final SyncEngine sync;
  final String tableName;

  BaseRepository({required this.sync, required this.tableName});

  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> save(T item);
  Future<void> delete(String id);

  Future<void> queueUpsert(Map<String, dynamic> payload, String id) async {
    await sync.queueChange(
      tableName: tableName,
      operation: 'UPDATE',
      payload: payload,
      recordId: id,
    );
  }

  Future<void> queueInsert(Map<String, dynamic> payload) async {
    await sync.queueChange(
      tableName: tableName,
      operation: 'INSERT',
      payload: payload,
    );
  }

  Future<void> queueDelete(String id) async {
    await sync.queueChange(
      tableName: tableName,
      operation: 'DELETE',
      payload: {},
      recordId: id,
    );
  }
}
