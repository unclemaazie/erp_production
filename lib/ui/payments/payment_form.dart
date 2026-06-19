import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';

class PaymentFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const PaymentFormDialog({super.key, required this.onSaved});

  @override
  State<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String? _customerId;
  String? _invoiceId;
  String _method = 'cash';
  DateTime _date = DateTime.now();
  List<Customer> _customers = [];
  List<Invoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await LocalDB.instance;
    final cRows = await db.query('customers', where: 'deleted_at IS NULL', orderBy: 'name ASC');
    final iRows = await db.query('invoices', where: "deleted_at IS NULL AND status IN ('sent','overdue')", orderBy: 'due_date ASC');
    setState(() {
      _customers = cRows.map(Customer.fromMap).toList();
      _invoices = iRows.map(Invoice.fromMap).toList();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = await LocalDB.instance;
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    await db.insert('payments', {
      'id': id,
      'customer_id': _customerId,
      'invoice_id': _invoiceId,
      'amount': double.parse(_amountCtrl.text),
      'method': _method,
      'reference_number': _refCtrl.text.isEmpty ? null : _refCtrl.text,
      'payment_date': _date.toIso8601String(),
      'allocated': _invoiceId != null ? 1 : 0,
      'created_at': now,
      'updated_at': now,
      'sync_status': 0,
    });

    // If allocated to invoice, update invoice amount_paid
    if (_invoiceId != null) {
      final invRows = await db.query('invoices', where: 'id = ?', whereArgs: [_invoiceId]);
      if (invRows.isNotEmpty) {
        final inv = Invoice.fromMap(invRows.first);
        final newPaid = inv.amountPaid + double.parse(_amountCtrl.text);
        final newBalance = inv.total - newPaid;
        String newStatus = inv.status;
        if (newBalance <= 0) newStatus = 'paid';
        else if (inv.dueDate != null && inv.dueDate!.isBefore(DateTime.now())) newStatus = 'overdue';
        else newStatus = 'sent';

        await db.update('invoices', {
          'amount_paid': newPaid,
          'balance_due': newBalance > 0 ? newBalance : 0,
          'status': newStatus,
          'updated_at': now,
          'sync_status': 0,
        }, where: 'id = ?', whereArgs: [_invoiceId]);
      }
    }

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _customerId,
                decoration: const InputDecoration(labelText: 'Customer'),
                items: _customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _customerId = v),
              ),
              DropdownButtonFormField<String>(
                value: _invoiceId,
                decoration: const InputDecoration(labelText: 'Allocate to Invoice (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Unallocated')),
                  ..._invoices.map((i) => DropdownMenuItem(
                    value: i.id,
                    child: Text('${i.invoiceNumber ?? 'Draft'} - R ${i.balanceDue.toStringAsFixed(2)}'),
                  )),
                ],
                onChanged: (v) => setState(() => _invoiceId = v),
              ),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount *'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid amount' : null,
              ),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                ],
                onChanged: (v) => setState(() => _method = v!),
              ),
              TextField(
                controller: _refCtrl,
                decoration: const InputDecoration(labelText: 'Reference Number'),
              ),
              ListTile(
                title: const Text('Payment Date'),
                subtitle: Text(_date.toIso8601String().split('T').first),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _date = d);
                },
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
