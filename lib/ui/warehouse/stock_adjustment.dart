import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/product.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const StockAdjustmentDialog({super.key, required this.onSaved});

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _productId;
  final _qtyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _type = 'adjustment';
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final db = await LocalDB.instance;
    final rows = await db.query('products', where: 'deleted_at IS NULL', orderBy: 'name ASC');
    setState(() => _products = rows.map(Product.fromMap).toList());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _productId == null) return;
    final db = await LocalDB.instance;
    final now = DateTime.now().toIso8601String();
    final qty = double.parse(_qtyCtrl.text);

    // Get current stock
    final invRows = await db.query('inventory', where: 'product_id = ?', whereArgs: [_productId]);
    if (invRows.isEmpty) {
      await db.insert('inventory', {
        'id': const Uuid().v4(),
        'product_id': _productId,
        'warehouse_id': 'default',
        'quantity_on_hand': qty,
        'quantity_reserved': 0,
        'reorder_level': 0,
        'created_at': now,
        'updated_at': now,
        'sync_status': 0,
      });
    } else {
      final current = (invRows.first['quantity_on_hand'] as num).toDouble();
      await db.update('inventory', {
        'quantity_on_hand': current + qty,
        'updated_at': now,
        'sync_status': 0,
      }, where: 'product_id = ?', whereArgs: [_productId]);
    }

    // Log movement
    await db.insert('stock_movements', {
      'id': const Uuid().v4(),
      'product_id': _productId,
      'warehouse_id': 'default',
      'movement_type': _type,
      'quantity': qty,
      'reason': _reasonCtrl.text.trim(),
      'created_at': now,
      'sync_status': 0,
    });

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stock Adjustment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _productId,
                decoration: const InputDecoration(labelText: 'Product *'),
                items: _products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) => setState(() => _productId = v),
                validator: (v) => v == null ? 'Select product' : null,
              ),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
                  DropdownMenuItem(value: 'inbound', child: Text('Inbound / GRN')),
                  DropdownMenuItem(value: 'outbound', child: Text('Outbound / Sale')),
                  DropdownMenuItem(value: 'damage', child: Text('Damage / Loss')),
                  DropdownMenuItem(value: 'recount', child: Text('Recount')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              TextFormField(
                controller: _qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity Change *'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid number' : null,
              ),
              TextField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
