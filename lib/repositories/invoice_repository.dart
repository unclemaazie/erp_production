import '../core/db/local_db.dart';
import '../core/sync/sync_engine.dart';
import '../models/invoice.dart';
import 'base_repository.dart';

class InvoiceRepository extends BaseRepository<Invoice> {
  InvoiceRepository({required SyncEngine sync})
      : super(sync: sync, tableName: 'invoices');

  @override
  Future<List<Invoice>> getAll() async {
    final db = await LocalDB.instance;
    final rows = await db.query(
      tableName,
      where: 'deleted_at IS NULL',
      orderBy: 'issue_date DESC',
    );
    return rows.map(Invoice.fromMap).toList();
  }

  Future<List<Invoice>> getByStatus(String status) async {
    final db = await LocalDB.instance;
    final rows = await db.query(
      tableName,
      where: 'deleted_at IS NULL AND status = ?',
      whereArgs: [status],
      orderBy: 'due_date ASC',
    );
    return rows.map(Invoice.fromMap).toList();
  }

  @override
  Future<Invoice?> getById(String id) async {
    final db = await LocalDB.instance;
    final rows = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Invoice.fromMap(rows.first);
  }

  Future<List<InvoiceLineItem>> getLineItems(String invoiceId) async {
    final db = await LocalDB.instance;
    final rows = await db.query(
      'invoice_line_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return rows.map(InvoiceLineItem.fromMap).toList();
  }

  Future<void> saveLineItem(InvoiceLineItem item) async {
    final db = await LocalDB.instance;
    final map = item.toMap();
    await db.insert('invoice_line_items', map, conflictAlgorithm: ConflictAlgorithm.replace);
    await sync.queueChange(
      tableName: 'invoice_line_items',
      operation: 'INSERT',
      payload: map,
      recordId: item.id,
    );
  }

  @override
  Future<void> save(Invoice invoice) async {
    final db = await LocalDB.instance;
    final map = invoice.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    map['sync_status'] = 0;

    final existing = await db.query(tableName, where: 'id = ?', whereArgs: [invoice.id]);
    if (existing.isEmpty) {
      map['created_at'] = DateTime.now().toIso8601String();
      await db.insert(tableName, map);
      await queueInsert(map);
    } else {
      await db.update(tableName, map, where: 'id = ?', whereArgs: [invoice.id]);
      await queueUpsert(map, invoice.id);
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
