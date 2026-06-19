import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../models/product.dart';

class InvoiceForm extends ConsumerStatefulWidget {
  final String? invoiceId;
  const InvoiceForm({super.key, this.invoiceId});

  @override
  ConsumerState<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends ConsumerState<InvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  String? _customerId;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final List<_LineItem> _lines = [];
  double _subtotal = 0;
  double _taxTotal = 0;
  double _total = 0;
  bool _isLoading = false;
  bool _isEdit = false;
  List<Customer> _customers = [];
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.invoiceId != null) {
      _isEdit = true;
      _loadInvoice();
    }
  }

  Future<void> _loadData() async {
    final db = await LocalDB.instance;
    final cRows = await db.query('customers', where: 'deleted_at IS NULL', orderBy: 'name ASC');
    final pRows = await db.query('products', where: 'deleted_at IS NULL', orderBy: 'name ASC');
    setState(() {
      _customers = cRows.map(Customer.fromMap).toList();
      _products = pRows.map(Product.fromMap).toList();
    });
  }

  Future<void> _loadInvoice() async {
    final db = await LocalDB.instance;
    final rows = await db.query('invoices', where: 'id = ?', whereArgs: [widget.invoiceId]);
    if (rows.isNotEmpty) {
      final inv = Invoice.fromMap(rows.first);
      _customerId = inv.customerId;
      _issueDate = inv.issueDate ?? DateTime.now();
      _dueDate = inv.dueDate ?? DateTime.now().add(const Duration(days: 30));
    }
    final lineRows = await db.query('invoice_line_items', where: 'invoice_id = ?', whereArgs: [widget.invoiceId]);
    for (final r in lineRows) {
      final li = InvoiceLineItem.fromMap(r);
      _lines.add(_LineItem(
        id: li.id,
        productId: li.productId,
        description: li.description,
        quantity: li.quantity,
        unitPrice: li.unitPrice,
        taxRate: li.taxRate,
      ));
    }
    _recalc();
  }

  void _recalc() {
    _subtotal = 0;
    _taxTotal = 0;
    for (final l in _lines) {
      final lineTotal = l.quantity * l.unitPrice;
      _subtotal += lineTotal;
      _taxTotal += lineTotal * (l.taxRate / 100);
    }
    _total = _subtotal + _taxTotal;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _customerId == null) return;
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item')),
      );
      return;
    }
    setState(() => _isLoading = true);

    final db = await LocalDB.instance;
    final id = widget.invoiceId ?? const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    final invNumber = _isEdit
        ? null
        : 'INV-${DateTime.now().year}-${(await db.rawQuery('SELECT COUNT(*) as c FROM invoices')).first['c']}';

    final cName = _customers.firstWhere((c) => c.id == _customerId).name;

    final map = {
      'id': id,
      'invoice_number': invNumber,
      'customer_id': _customerId,
      'customer_name': cName,
      'issue_date': _issueDate.toIso8601String(),
      'due_date': _dueDate.toIso8601String(),
      'status': 'draft',
      'subtotal': _subtotal,
      'tax_total': _taxTotal,
      'total': _total,
      'amount_paid': 0,
      'balance_due': _total,
      'updated_at': now,
      'sync_status': 0,
    };

    if (!_isEdit) {
      map['created_at'] = now;
      await db.insert('invoices', map);
    } else {
      await db.update('invoices', map, where: 'id = ?', whereArgs: [id]);
    }

    // Save line items
    await db.delete('invoice_line_items', where: 'invoice_id = ?', whereArgs: [id]);
    for (final l in _lines) {
      final lineMap = {
        'id': l.id,
        'invoice_id': id,
        'product_id': l.productId,
        'description': l.description,
        'quantity': l.quantity,
        'unit_price': l.unitPrice,
        'tax_rate': l.taxRate,
        'line_total': l.quantity * l.unitPrice * (1 + l.taxRate / 100),
        'created_at': now,
        'sync_status': 0,
      };
      await db.insert('invoice_line_items', lineMap);
    }

    if (mounted) context.pop();
  }

  void _addLine() {
    showDialog(
      context: context,
      builder: (_) => _LineItemDialog(
        products: _products,
        onAdd: (line) {
          setState(() => _lines.add(line));
          _recalc();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Invoice' : 'New Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _customerId,
                decoration: const InputDecoration(labelText: 'Customer *'),
                items: _customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _customerId = v),
                validator: (v) => v == null ? 'Select a customer' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Issue Date'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(_issueDate)),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _issueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _issueDate = d);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Due Date'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(_dueDate)),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _dueDate = d);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Line Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._lines.map((l) => Card(
                child: ListTile(
                  title: Text(l.description),
                  subtitle: Text('${l.quantity} x R ${l.unitPrice.toStringAsFixed(2)} @ ${l.taxRate}% tax'),
                  trailing: Text('R ${(l.quantity * l.unitPrice * (1 + l.taxRate / 100)).toStringAsFixed(2)}'),
                ),
              )),
              const Divider(height: 32),
              _totalRow('Subtotal', _subtotal),
              _totalRow('Tax', _taxTotal),
              _totalRow('Total', _total, bold: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Update Invoice' : 'Create Invoice'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('R ${value.toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14)),
        ],
      ),
    );
  }
}

class _LineItem {
  String id;
  String? productId;
  String description;
  double quantity;
  double unitPrice;
  double taxRate;
  _LineItem({required this.id, this.productId, required this.description, this.quantity = 1, this.unitPrice = 0, this.taxRate = 0});
}

class _LineItemDialog extends StatefulWidget {
  final List<Product> products;
  final void Function(_LineItem) onAdd;
  const _LineItemDialog({required this.products, required this.onAdd});

  @override
  State<_LineItemDialog> createState() => _LineItemDialogState();
}

class _LineItemDialogState extends State<_LineItemDialog> {
  String? _productId;
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _taxCtrl = TextEditingController(text: '15');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Line Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _productId,
              decoration: const InputDecoration(labelText: 'Product (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Custom item')),
                ...widget.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
              ],
              onChanged: (v) {
                setState(() => _productId = v);
                if (v != null) {
                  final p = widget.products.firstWhere((x) => x.id == v);
                  _descCtrl.text = p.name;
                  _priceCtrl.text = p.unitPrice.toString();
                  _taxCtrl.text = p.taxRate.toString();
                }
              },
            ),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: _qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            TextField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'Unit Price'), keyboardType: TextInputType.number),
            TextField(controller: _taxCtrl, decoration: const InputDecoration(labelText: 'Tax %'), keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(_LineItem(
              id: const Uuid().v4(),
              productId: _productId,
              description: _descCtrl.text,
              quantity: double.tryParse(_qtyCtrl.text) ?? 1,
              unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
              taxRate: double.tryParse(_taxCtrl.text) ?? 0,
            ));
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
