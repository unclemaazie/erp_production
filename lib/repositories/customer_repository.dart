import '../core/db/local_db.dart';
import '../core/sync/sync_engine.dart';
import '../models/customer.dart';
import 'base_repository.dart';

class CustomerRepository extends BaseRepository<Customer> {
  CustomerRepository({required SyncEngine sync})
      : super(sync: sync, tableName: 'customers');

  @override
  Future<List<Customer>> getAll() async {
    final db = await LocalDB.instance;
    final rows = await db.query(
      tableName,
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<List<Customer>> search(String query) async {
    final db = await LocalDB.instance;
    final rows = await db.query(
      tableName,
      where: 'deleted_at IS NULL AND (name LIKE ? OR email LIKE ? OR phone LIKE ?)',
      whereArgs: ['%\$query%', '%\$query%', '%\$query%'],
      orderBy: 'name ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  @override
  Future<Customer?> getById(String id) async {
    final db = await LocalDB.instance;
    final rows = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  @override
  Future<void> save(Customer customer) async {
    final db = await LocalDB.instance;
    final map = customer.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    map['sync_status'] = 0;

    final existing = await db.query(tableName, where: 'id = ?', whereArgs: [customer.id]);
    if (existing.isEmpty) {
      map['created_at'] = DateTime.now().toIso8601String();
      await db.insert(tableName, map);
      await queueInsert(map);
    } else {
      await db.update(tableName, map, where: 'id = ?', whereArgs: [customer.id]);
      await queueUpsert(map, customer.id);
    }
  }

  @override
  Future<void> delete(String id) async {
    final db = await LocalDB.instance;
    await db.update(
      tableName,
      {'deleted_at': DateTime.now().toIso8601String(), 'sync_status': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await queueDelete(id);
  }
}
