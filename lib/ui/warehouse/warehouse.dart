import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/product.dart';
import 'stock_adjustment.dart';

class Warehouse extends ConsumerStatefulWidget {
  const Warehouse({super.key});

  @override
  ConsumerState<Warehouse> createState() => _WarehouseState();
}

class _WarehouseState extends ConsumerState<Warehouse> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse'),
        bottom: TabBar(
          onTap: (i) => setState(() => _tab = i),
          tabs: const [
            Tab(text: 'Stock Levels'),
            Tab(text: 'Movements'),
            Tab(text: 'Low Stock'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _StockLevelsTab(onChanged: () => setState(() {})),
          const _MovementsTab(),
          const _LowStockTab(),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => StockAdjustmentDialog(onSaved: () => setState(() {})),
              ),
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }
}

class _StockLevelsTab extends StatelessWidget {
  final VoidCallback onChanged;
  const _StockLevelsTab({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return const Center(child: Text('No stock data', style: TextStyle(color: AppTheme.textSecondary)));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final item = list[i];
            final product = item['product'] as Product;
            final qty = (item['quantity_on_hand'] as num).toDouble();
            final reorder = (item['reorder_level'] as num).toDouble();
            final isLow = qty <= reorder;
            return ListTile(
              leading: Container(
                width: 4,
                height: 40,
                color: isLow ? AppTheme.danger : AppTheme.success,
              ),
              title: Text(product.name),
              subtitle: Text('SKU: ${product.sku ?? 'N/A'}'),
              trailing: Text(
                '${qty.toStringAsFixed(0)} units',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isLow ? AppTheme.danger : AppTheme.textPrimary,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final db = await LocalDB.instance;
    final rows = await db.rawQuery('''
      SELECT i.*, p.name, p.sku
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      WHERE p.deleted_at IS NULL
      ORDER BY p.name ASC
    ''');
    return rows.map((r) => {
      'product': Product.fromMap(r),
      'quantity_on_hand': r['quantity_on_hand'],
      'reorder_level': r['reorder_level'],
    }).toList();
  }
}

class _MovementsTab extends StatelessWidget {
  const _MovementsTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return const Center(child: Text('No movements', style: TextStyle(color: AppTheme.textSecondary)));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final m = list[i];
            return ListTile(
              leading: Icon(
                m['movement_type'] == 'inbound' ? Icons.arrow_downward : Icons.arrow_upward,
                color: m['movement_type'] == 'inbound' ? AppTheme.success : AppTheme.danger,
              ),
              title: Text('${m['product_name']}'),
              subtitle: Text('${m['movement_type']} • ${m['reason'] ?? 'No reason'}'),
              trailing: Text('${m['quantity'].toStringAsFixed(0)}'),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final db = await LocalDB.instance;
    final rows = await db.rawQuery('''
      SELECT sm.*, p.name as product_name
      FROM stock_movements sm
      JOIN products p ON sm.product_id = p.id
      ORDER BY sm.created_at DESC
      LIMIT 100
    ''');
    return rows.map((r) => {
      'product_name': r['product_name'],
      'movement_type': r['movement_type'],
      'quantity': (r['quantity'] as num).toDouble(),
      'reason': r['reason'],
    }).toList();
  }
}

class _LowStockTab extends StatelessWidget {
  const _LowStockTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return const Center(child: Text('All stock levels healthy', style: TextStyle(color: AppTheme.success)));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final item = list[i];
            return ListTile(
              leading: const Icon(Icons.warning, color: AppTheme.danger),
              title: Text(item['name'] as String),
              subtitle: Text('SKU: ${item['sku'] ?? 'N/A'}'),
              trailing: Text(
                '${item['quantity_on_hand'].toStringAsFixed(0)} / ${item['reorder_level'].toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final db = await LocalDB.instance;
    final rows = await db.rawQuery('''
      SELECT i.*, p.name, p.sku
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      WHERE p.deleted_at IS NULL AND i.quantity_on_hand <= i.reorder_level
      ORDER BY (i.quantity_on_hand / i.reorder_level) ASC
    ''');
    return rows.map((r) => {
      'name': r['name'],
      'sku': r['sku'],
      'quantity_on_hand': (r['quantity_on_hand'] as num).toDouble(),
      'reorder_level': (r['reorder_level'] as num).toDouble(),
    }).toList();
  }
}
