import '../core/db/local_db.dart';
import '../core/sync/sync_engine.dart';
import '../models/product.dart';
import 'base_repository.dart';

class ProductRepository extends BaseRepository<Product> {
  ProductRepository({required SyncEngine sync})
      : super(sync: sync, tableName: 'products');

  @override
  Future<List<Product>> getAll() async {
    final db = await LocalDB.instance;
    final rows = await db.query(
      tableName,
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  @override
  Future<Product?> getById(String id) async {
    final db = await LocalDB.instance;
    final rows = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  @override
  Future<void> save(Product product) async {
    final db = await LocalDB.instance;
    final map = product.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    map['sync_status'] = 0;

    final existing = await db.query(tableName, where: 'id = ?', whereArgs: [product.id]);
    if (existing.isEmpty) {
      map['created_at'] = DateTime.now().toIso8601String();
      await db.insert(tableName, map);
      await queueInsert(map);
    } else {
      await db.update(tableName, map, where: 'id = ?', whereArgs: [product.id]);
      await queueUpsert(map, product.id);
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
